const DEFAULT_MODEL = "gpt-5.4-mini";
const DEFAULT_TEXT_BASE_URL = "https://api.openai.com/v1";
// "none" é o tier mais rápido do gpt-5.4 (sem reasoning tokens). Validado
// contra a lista de valores suportados retornada pela própria API.
// Para reverter sem deploy: OPENAI_REASONING_EFFORT=low no Vercel.
const DEFAULT_REASONING_EFFORT = "none";
const DEFAULT_TTS_MODEL = "eleven_flash_v2_5";
const DEFAULT_TTS_VOICE_ID = "21m00Tcm4TlvDq8ikWAM";
const DEFAULT_TTS_SPEED = 0.92;
// A escolha final do produto é uma voz masculina pt-BR. A variável de ambiente
// permite trocá-la sem novo deploy.
const DEFAULT_AZURE_SPEECH_VOICE = "pt-BR-AntonioNeural";
const DEFAULT_AZURE_SPEECH_RATE = "-10%";
const DEFAULT_AZURE_SPEECH_PITCH = "-3%";
const DEFAULT_AZURE_SPEECH_BREAK_MS = 500;
const AZURE_REFERENCE_SPEECH_VERSION = "v1";
const DEFAULT_TIMEOUT_MS = 25000;
const DEFAULT_RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const DEFAULT_RATE_LIMIT_MAX_REQUESTS = 24;
const SESSION_ITEM_COUNT = 3;
const rateLimitBuckets = globalThis.__limiarAIRateLimitBuckets || new Map();
globalThis.__limiarAIRateLimitBuckets = rateLimitBuckets;

// A IA gera somente os campos de explicação. Referência e texto bíblico são
// fixados pelo servidor a partir dos trechos selecionados — a IA nunca escolhe
// nem reescreve versículos.
const explanationFieldsSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    homily: { type: "string" },
    spiritualMeaning: { type: "string" },
    practicalApplication: { type: "string" },
    conclusion: { type: "string" },
    meditationQuestion: { type: "string" }
  },
  required: [
    "homily",
    "spiritualMeaning",
    "practicalApplication",
    "conclusion",
    "meditationQuestion"
  ]
};

// Sem minItems/maxItems: o modo strict do structured outputs não aceita
// restrições de tamanho de array. A contagem exata é imposta pelo prompt e
// validada pelo servidor em validateExplanationItems.
function explanationItemsSchema() {
  return {
    type: "array",
    items: explanationFieldsSchema
  };
}

function readingSessionExplanationSchema(itemCount = SESSION_ITEM_COUNT) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      items: explanationItemsSchema(),
      reflection: explanationFieldsSchema
    },
    required: ["items", "reflection"]
  };
}

function spiritualReadingExplanationSchema(itemCount = SESSION_ITEM_COUNT) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      items: explanationItemsSchema()
    },
    required: ["items"]
  };
}

const reflectionExplanationSchema = explanationFieldsSchema;

function applyCommonHeaders(res) {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
}

function applyAudioHeaders(res) {
  res.setHeader("Content-Type", "audio/mpeg");
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
}

function requirePost(req, res) {
  if (req.method === "POST") return true;
  res.statusCode = 405;
  res.setHeader("Allow", "POST");
  res.end(JSON.stringify({ error: "method_not_allowed" }));
  return false;
}

function requestContext(req, endpoint) {
  const clientID = trimText(
    req.headers?.["x-limiar-client-id"] || req.headers?.["x-vercel-id"] || "",
    120
  );
  const forwardedFor = trimText(req.headers?.["x-forwarded-for"] || "", 180)
    .split(",")[0]
    .trim();
  const key = clientID || forwardedFor || "unknown-client";
  return {
    endpoint,
    clientID: clientID || undefined,
    rateLimitKey: `${endpoint}:${key}`,
    requestID: trimText(req.headers?.["x-vercel-id"] || req.headers?.["x-request-id"] || "", 160) || undefined
  };
}

// Segredo compartilhado do app. Só é exigido quando LIMIAR_APP_SECRET está
// configurado no ambiente — assim o backend pode ser publicado antes do build
// do app que envia o header, e o env só é ativado quando a adoção permitir
// (builds antigos do TestFlight não enviam o header).
function validateAppSecret(req) {
  const expected = trimText(process.env.LIMIAR_APP_SECRET, 200);
  if (!expected) return true;
  const provided = trimText(req.headers?.["x-limiar-app-key"] || "", 200);
  if (!provided || provided.length !== expected.length) return false;
  const crypto = require("node:crypto");
  return crypto.timingSafeEqual(Buffer.from(provided), Buffer.from(expected));
}

// Porteiro dos endpoints de IA: valida o segredo do app e aplica o rate limit.
function enforceAIRateLimit(req, res, endpoint) {
  const context = requestContext(req, endpoint);

  if (!validateAppSecret(req)) {
    console.warn("limiar_ai_unauthorized", {
      endpoint,
      requestID: context.requestID,
      clientID: context.clientID
    });
    res.statusCode = 401;
    res.end(JSON.stringify({ error: "unauthorized" }));
    return { allowed: false, context };
  }

  const now = Date.now();
  const windowMs = Number(process.env.LIMIAR_AI_RATE_LIMIT_WINDOW_MS || DEFAULT_RATE_LIMIT_WINDOW_MS);
  const maxRequests = Number(process.env.LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS || DEFAULT_RATE_LIMIT_MAX_REQUESTS);
  const bucket = rateLimitBuckets.get(context.rateLimitKey) || { count: 0, resetAt: now + windowMs };

  if (now > bucket.resetAt) {
    bucket.count = 0;
    bucket.resetAt = now + windowMs;
  }

  bucket.count += 1;
  rateLimitBuckets.set(context.rateLimitKey, bucket);

  if (bucket.count <= maxRequests) {
    return { allowed: true, context };
  }

  const retryAfter = Math.max(1, Math.ceil((bucket.resetAt - now) / 1000));
  console.warn("limiar_ai_rate_limited", {
    endpoint,
    requestID: context.requestID,
    clientID: context.clientID,
    retryAfter
  });
  res.statusCode = 429;
  res.setHeader("Retry-After", String(retryAfter));
  res.end(JSON.stringify({ error: "ai_rate_limited" }));
  return { allowed: false, context };
}

function parseBody(req) {
  if (typeof req.body === "object" && req.body !== null) return req.body;
  if (typeof req.body === "string" && req.body.trim()) return JSON.parse(req.body);
  return {};
}

function nonEmpty(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function trimText(value, maxLength = 4000) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function compactList(values, max = 12) {
  if (!Array.isArray(values)) return [];
  return values.filter(nonEmpty).map((value) => value.trim()).slice(0, max);
}

function normalizeProfile(profile = {}) {
  return {
    tradition: trimText(profile.tradition, 80) || "Católica",
    traditionID: trimText(profile.traditionID, 80),
    favoriteSections: compactList(profile.favoriteSections, 8),
    favoriteSectionIDs: compactList(profile.favoriteSectionIDs, 8),
    favoriteBooks: compactList(profile.favoriteBooks, 40),
    favoriteBookIDs: compactList(profile.favoriteBookIDs, 40),
    priorityBooks: compactList(profile.priorityBooks, 40),
    priorityBookIDs: compactList(profile.priorityBookIDs, 40),
    favoriteThemes: compactList(profile.favoriteThemes, 12),
    favoriteThemeIDs: compactList(profile.favoriteThemeIDs, 12),
    explanationDepth: normalizeDepth(profile.explanationDepth),
    avoidedSections: compactList(profile.avoidedSections, 8),
    avoidedBooks: compactList(profile.avoidedBooks, 40),
    toneGuidance: trimText(profile.toneGuidance, 500)
  };
}

function normalizeDepth(value) {
  const normalized = trimText(value, 40)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
  if (["curta", "short", "breve"].includes(normalized)) return "curta";
  if (["media", "medium", "moderada", "equilibrada"].includes(normalized)) return "média";
  if (["grande", "profunda", "mais profunda", "deep", "long", "detalhada"].includes(normalized)) {
    return "grande";
  }
  return "média";
}

// Mantém compatibilidade binária com builds publicados: sem `itemCount`, a
// sessão continua com três itens e respeita a profundidade antiga. Builds
// novos enviam a contagem; o card único usa a diretriz curta enriquecida e os
// demais mantêm a explicação média como régua fixa.
function resolveReadingSessionOptions(body = {}, profileDepth = "média", passageCount = SESSION_ITEM_COUNT) {
  const hasItemCount = Object.prototype.hasOwnProperty.call(body, "itemCount")
    && body.itemCount !== null
    && body.itemCount !== undefined;
  const numericCount = Number(body.itemCount);
  const requestedItemCount = hasItemCount && Number.isFinite(numericCount)
    ? Math.max(1, Math.min(SESSION_ITEM_COUNT, Math.trunc(numericCount)))
    : SESSION_ITEM_COUNT;
  const availableCount = Math.max(0, Math.trunc(Number(passageCount) || 0));
  const itemCount = Math.min(requestedItemCount, availableCount);
  const generationDepth = hasItemCount
    ? (itemCount === 1 ? "curta" : "média")
    : normalizeDepth(profileDepth);

  return {
    hasItemCount,
    requestedItemCount,
    itemCount,
    generationDepth,
    outputBudgetDepth: generationDepth
  };
}

function depthGuidance(depth) {
  if (depth === "curta") {
    return [
      "Profundidade curta:",
      "- A profundidade curta significa um único trecho, não uma explicação rasa. Explore esse trecho por inteiro com a mesma riqueza editorial da profundidade mais profunda;",
      "- homily: 2 a 3 parágrafos desenvolvidos. Contextualize quem fala, para quem e em que situação. Explique o trecho por inteiro e conecte-o de modo natural à tradição informada;",
      "- spiritualMeaning: denso, conectando o trecho, um tema preferido e a vida concreta;",
      "- practicalApplication: 2 a 3 frases com uma decisão clara e aplicável hoje, sem moralismo;",
      "- conclusion: 1 a 2 frases, pastorais e específicas;",
      "- meditationQuestion: pergunta capaz de sustentar um minuto de meditação;",
      "- Não redundância: practicalApplication e meditationQuestion não podem repetir ideias nem frases da homily. Devem avançar a reflexão, nunca resumi-la."
    ].join("\n");
  }
  if (depth === "grande") {
    return [
      "Profundidade mais profunda:",
      "- homily: 2 a 3 parágrafos desenvolvidos, com contexto do trecho e ligação com a tradição;",
      "- spiritualMeaning: explique com mais densidade espiritual, conectando trecho, tema preferido e vida concreta;",
      "- practicalApplication: aplicação prática mais elaborada, sem moralismo, com uma decisão clara para o restante do dia;",
      "- conclusion: frase final pastoral e específica, diferente das respostas anteriores;",
      "- meditationQuestion: pergunta mais reflexiva, capaz de sustentar meditação."
    ].join("\n");
  }
  return [
    "Profundidade média:",
    "- homily: 1 a 2 parágrafos equilibrados;",
    "- spiritualMeaning: explique o sentido espiritual e conecte com a rotina do usuário;",
    "- practicalApplication: orientação concreta para a próxima pausa;",
    "- conclusion: curta, acolhedora e específica;",
    "- meditationQuestion: pergunta simples e aberta."
  ].join("\n");
}

// Budgets contam também os reasoning tokens do modelo (Responses API),
// por isso têm folga sobre o tamanho esperado do JSON final.
function depthOutputTokenLimit(depth, endpoint) {
  if (endpoint === "reading-session") {
    if (depth === "curta") return 2800;
    if (depth === "grande") return 4200;
    return 2800;
  }
  const isReading = endpoint === "spiritual-reading";
  if (depth === "curta") return isReading ? 2400 : 1400;
  if (depth === "grande") return isReading ? 3600 : 2000;
  return isReading ? 2400 : 1300;
}

function diagnosticEnabled() {
  return process.env.LIMIAR_AI_DEBUG === "1" || process.env.NODE_ENV !== "production";
}

// Provider/modelo efetivos por tipo de evento: eventos de narração carimbam o
// motor de TTS ativo; os demais, o modelo textual. `details` pode sobrepor.
function providerInfo(event = "") {
  const isSpeechEvent = /^(tts_|azure_tts_|elevenlabs_)/.test(event);
  if (!isSpeechEvent) {
    return { provider: "openai", model: process.env.OPENAI_MODEL || DEFAULT_MODEL };
  }
  if (normalizeTTSProvider() === "azure") {
    return { provider: "azure", model: "azure-speech", voice: azureSpeechVoice() };
  }
  return { provider: "elevenlabs", model: process.env.ELEVENLABS_TTS_MODEL || DEFAULT_TTS_MODEL };
}

function logAIDiagnostic(event, details = {}) {
  if (!diagnosticEnabled()) return;
  console.info("limiar_ai_diagnostic", {
    event,
    ...providerInfo(event),
    ...details
  });
}

function promptDebugDetails(prompt) {
  if (process.env.LIMIAR_AI_DEBUG_PROMPT !== "1") return {};
  return {
    promptPreview: prompt.slice(0, 2400),
    promptTruncated: prompt.length > 2400
  };
}

function normalizePassages(passages = []) {
  if (!Array.isArray(passages)) return [];
  return passages
    .map((passage) => ({
      id: trimText(passage.id, 120),
      title: trimText(passage.title, 140),
      reference: trimText(passage.reference, 160),
      text: trimText(passage.text, 1600),
      theme: trimText(passage.theme, 80),
      section: trimText(passage.section, 80),
      book: trimText(passage.book, 80)
    }))
    .filter((passage) => nonEmpty(passage.reference) && nonEmpty(passage.text))
    .slice(0, 48);
}

function normalizeRecentReflections(reflections = []) {
  if (!Array.isArray(reflections)) return [];
  return reflections
    .map((item) => ({
      reference: trimText(item.reference, 160),
      summary: trimText(item.summary, 360),
      meditationQuestion: trimText(item.meditationQuestion, 220)
    }))
    .filter((item) => nonEmpty(item.reference) || nonEmpty(item.summary))
    .slice(0, 8);
}

function normalizeContentIdentity(value) {
  return trimText(value, 2000)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function recentIdentitySet(recentPassageIDs = []) {
  return new Set(compactList(recentPassageIDs, 80).map(normalizeContentIdentity).filter(Boolean));
}

function passageIdentities(passage = {}) {
  return [
    normalizeContentIdentity(passage.id),
    normalizeContentIdentity(passage.reference),
    normalizeContentIdentity(passage.text)
  ].filter(Boolean);
}

function stableHash(value) {
  let hash = 5381;
  const text = String(value);
  for (let index = 0; index < text.length; index += 1) {
    hash = ((hash << 5) + hash + text.charCodeAt(index)) >>> 0;
  }
  return hash;
}

// Seleção determinística dos trechos da sessão. A IA não participa desta etapa:
// 1. Filtro forte: livros preferidos primeiro; amplia para seções preferidas e
//    depois para todo o pool apenas quando não há trechos suficientes.
// 2. Anti-repetição: trechos recentes só entram quando o pool fresco esgota e,
//    nesse caso, entra primeiro o menos recentemente usado (rotação LRU).
// 3. Desempate estável por semente (dia + cliente) para variar entre dias sem
//    perder determinismo dentro da mesma requisição.
function selectSessionPassages({ profile, passages, recentPassageIDs = [], count = SESSION_ITEM_COUNT, seed = "" }) {
  const recent = recentIdentitySet(recentPassageIDs);
  const recencyRank = new Map();
  compactList(recentPassageIDs, 80).forEach((value, index) => {
    const identity = normalizeContentIdentity(value);
    if (identity && !recencyRank.has(identity)) recencyRank.set(identity, index);
  });

  const favoriteBooks = new Set(profile.favoriteBooks.map(normalizeContentIdentity).filter(Boolean));
  const priorityBooks = new Set(profile.priorityBooks.map(normalizeContentIdentity).filter(Boolean));
  const favoriteSections = new Set(profile.favoriteSections.map(normalizeContentIdentity).filter(Boolean));
  const favoriteThemes = new Set(profile.favoriteThemes.map(normalizeContentIdentity).filter(Boolean));
  const avoidedBooks = new Set(profile.avoidedBooks.map(normalizeContentIdentity).filter(Boolean));
  const avoidedSections = new Set(profile.avoidedSections.map(normalizeContentIdentity).filter(Boolean));

  const candidates = passages
    .filter((passage) => {
      const book = normalizeContentIdentity(passage.book);
      const section = normalizeContentIdentity(passage.section);
      if (book && avoidedBooks.has(book)) return false;
      if (section && avoidedSections.has(section)) return false;
      return true;
    })
    .map((passage, index) => {
      const identities = passageIdentities(passage);
      const isRecent = identities.some((identity) => recent.has(identity));
      let lastUsedRank = Infinity;
      for (const identity of identities) {
        if (recencyRank.has(identity)) {
          lastUsedRank = Math.min(lastUsedRank, recencyRank.get(identity));
        }
      }
      const book = normalizeContentIdentity(passage.book);
      const section = normalizeContentIdentity(passage.section);
      const theme = normalizeContentIdentity(passage.theme);
      let score = 0;
      if (book && favoriteBooks.has(book)) score += 4;
      if (section && favoriteSections.has(section)) score += 3;
      if (theme && favoriteThemes.has(theme)) score += 2;
      return {
        passage,
        index,
        isRecent,
        lastUsedRank,
        inFavoriteBooks: Boolean(book && favoriteBooks.has(book)),
        inPriorityBooks: Boolean(book && priorityBooks.has(book)),
        inFavoriteSections: Boolean(section && favoriteSections.has(section)),
        score,
        jitter: stableHash(`${seed}|${passage.id || passage.reference}`)
      };
    });

  const tiers = [];
  if (favoriteBooks.size) {
    tiers.push({ name: "favorite-books", accepts: (entry) => entry.inFavoriteBooks });
  }
  if (favoriteSections.size) {
    tiers.push({
      name: "favorite-sections",
      accepts: (entry) => entry.inFavoriteBooks || entry.inFavoriteSections
    });
  }
  tiers.push({ name: "full-pool", accepts: () => true });

  const byPreference = (lhs, rhs) =>
    rhs.score - lhs.score || lhs.jitter - rhs.jitter || lhs.index - rhs.index;

  const selected = [];
  const selectedIndexes = new Set();
  let selectionTier = tiers[0]?.name || "full-pool";
  let reusedRecentCount = 0;

  const byLeastRecentlyUsed = (lhs, rhs) =>
    rhs.lastUsedRank - lhs.lastUsedRank || byPreference(lhs, rhs);

  const reusedIndexes = new Set();
  const addEntry = (entry, reusedRecent = false) => {
    selected.push(entry);
    selectedIndexes.add(entry.index);
    if (reusedRecent) {
      reusedRecentCount += 1;
      reusedIndexes.add(entry.index);
    }
  };

  // O afinamento é prioridade, não filtro. A cota degrada com a travessia:
  // 3 itens = 2 afinados + 1 descoberta; 2 = 1 + 1; 1 = melhor afinado.
  const priorityQuota = priorityBooks.size
    ? (count >= 3 ? 2 : Math.min(1, count))
    : 0;
  for (const entry of candidates
    .filter((candidate) => candidate.inPriorityBooks && !candidate.isRecent)
    .sort(byPreference)
    .slice(0, priorityQuota)) {
    addEntry(entry);
  }

  for (const tier of tiers) {
    if (selected.length >= count) break;
    const pool = candidates.filter(
      (entry) => tier.accepts(entry) && !selectedIndexes.has(entry.index)
    );
    const fresh = pool
      .filter((entry) => !entry.isRecent)
      .sort((lhs, rhs) => {
        if (priorityBooks.size && lhs.inPriorityBooks !== rhs.inPriorityBooks) {
          return lhs.inPriorityBooks ? 1 : -1;
        }
        return byPreference(lhs, rhs);
      });
    for (const entry of fresh) {
      addEntry(entry);
      if (selected.length >= count) break;
    }
    selectionTier = tier.name;
    if (selected.length >= count) break;

    // Preferência é filtro forte: antes de ampliar para o próximo nível,
    // rotaciona os menos recentemente usados DESTE nível. Só amplia quando o
    // nível não tem trechos suficientes no total — a explicação gerada é
    // sempre nova, então repetir um versículo antigo é melhor do que trazer
    // um livro que o usuário não escolheu. A soma inclui os já selecionados
    // pela cota de prioridade, que consome trechos deste mesmo nível.
    if (selected.length + pool.length >= count) {
      const leastRecentFirst = pool
        .filter((entry) => !selectedIndexes.has(entry.index))
        .sort(byLeastRecentlyUsed);
      for (const entry of leastRecentFirst) {
        addEntry(entry, true);
        if (selected.length >= count) break;
      }
    }
    if (selected.length >= count) break;
  }

  if (selected.length < count) {
    // Rede de segurança: completa com os menos recentemente usados do pool
    // inteiro, ainda priorizando as preferências.
    const leastRecentFirst = candidates
      .filter((entry) => !selectedIndexes.has(entry.index))
      .sort(byLeastRecentlyUsed);
    for (const entry of leastRecentFirst) {
      addEntry(entry, true);
      if (selected.length >= count) break;
    }
  }

  // Rede de segurança para temas — apenas para perfis novos, que enviam
  // priorityBooks: troca a janela de descoberta (nunca um trecho da cota) por
  // um candidato fresco do tema preferido, sem sair dos livros escolhidos.
  // Builds antigos (só favoriteBooks) mantêm o filtro forte original intacto.
  let favoriteThemeCount = selected.filter((entry) => favoriteThemes.has(normalizeContentIdentity(entry.passage.theme))).length;
  if (priorityBooks.size && favoriteThemes.size && favoriteThemeCount === 0) {
    const themeCandidate = candidates
      .filter((entry) =>
        !entry.isRecent &&
        !selectedIndexes.has(entry.index) &&
        favoriteThemes.has(normalizeContentIdentity(entry.passage.theme)) &&
        (!favoriteBooks.size || entry.inFavoriteBooks || entry.inPriorityBooks))
      .sort(byPreference)[0];
    const replacement = selected
      .filter((entry) => !entry.inPriorityBooks)
      .sort((lhs, rhs) => lhs.score - rhs.score || rhs.jitter - lhs.jitter || rhs.index - lhs.index)[0];
    if (themeCandidate && replacement) {
      const replacementIndex = selected.indexOf(replacement);
      selectedIndexes.delete(replacement.index);
      if (reusedIndexes.has(replacement.index)) {
        reusedRecentCount -= 1;
        reusedIndexes.delete(replacement.index);
      }
      selected[replacementIndex] = themeCandidate;
      selectedIndexes.add(themeCandidate.index);
      favoriteThemeCount = 1;
    }
  }

  return {
    selected: selected.slice(0, count).map((entry) => entry.passage),
    selectionTier,
    reusedRecentCount,
    priorityCount: selected.slice(0, count).filter((entry) => entry.inPriorityBooks).length,
    favoriteThemeCount,
    freshCount: candidates.filter((entry) => !entry.isRecent).length,
    candidateCount: candidates.length
  };
}

function buildSystemPrompt() {
  return [
    "Você é o motor de reflexão espiritual do app Limiar.",
    "Gere conteúdo em português do Brasil, com tom acolhedor, sóbrio e pastoral.",
    "Não use ponto e vírgula (;). Prefira frases curtas separadas por ponto final, ou reformule com conectivos naturais. A pontuação deve soar bem quando lida em voz alta.",
    "Os trechos bíblicos já foram escolhidos: escreva apenas as explicações pedidas para cada um deles, na ordem enviada.",
    "Não invente, não altere e não repita o texto bíblico dentro das explicações; apenas comente o sentido.",
    "Respeite a tradição informada. Para tradição judaica, não use Novo Testamento. Para espírita, use tom moral e de reforma íntima.",
    "Evite diagnóstico médico, aconselhamento clínico, promessas espirituais absolutas ou linguagem de autoridade religiosa institucional.",
    "Não inclua identificadores pessoais. Responda somente no JSON solicitado."
  ].join("\n");
}

function buildExplanationPrompt({ profile, selectedPassages, recentReflections = [], includeReflection }) {
  const passageBlock = selectedPassages
    .map((passage, index) => {
      return [
        `Trecho ${index + 1}`,
        `Referência: ${passage.reference}`,
        `Livro/seção/tema: ${[passage.book, passage.section, passage.theme].filter(Boolean).join(" / ")}`,
        `Texto: ${passage.text}`
      ].join("\n");
    })
    .join("\n\n");

  const historyBlock = recentReflections.length
    ? recentReflections
        .map((item) => `- ${item.reference}: ${item.summary} Pergunta anterior: ${item.meditationQuestion}`)
        .join("\n")
    : "- sem histórico recente";

  const lines = [
    "Preferências do usuário. Use estas escolhas como regras de personalização, não como contexto opcional:",
    `Tradição: ${profile.tradition}${profile.traditionID ? ` [${profile.traditionID}]` : ""}`,
    `Diretriz de tom da tradição: ${profile.toneGuidance || "não informado"}`,
    `Profundidade: ${profile.explanationDepth}`,
    depthGuidance(profile.explanationDepth),
    `Temas preferidos: ${profile.favoriteThemes.join(", ") || "não informado"}`,
    "",
    "Regras obrigatórias:",
    `- Gere explicações para exatamente ${selectedPassages.length} trechos, na mesma ordem em que foram enviados: items[0] corresponde ao Trecho 1, items[1] ao Trecho 2, e assim por diante.`,
    "- Em cada item, homily, spiritualMeaning, practicalApplication, conclusion e meditationQuestion devem ser específicos daquele trecho.",
    "- Integre pelo menos um tema preferido quando houver temas informados, de forma natural e coerente.",
    "- A profundidade escolhida define quantos trechos compõem a travessia. Preserve a mesma riqueza editorial em cada trecho, inclusive quando houver apenas um.",
    "- Varie aberturas, imagens e perguntas entre os itens e em relação ao histórico recente: nada de fórmulas fixas.",
    "- Evite respostas genéricas que funcionariam igualmente para qualquer tradição, tema ou profundidade."
  ];

  if (includeReflection) {
    lines.push(
      "",
      "Regras para reflection:",
      "- Gere uma reflexão única para o conjunto dos trechos.",
      "- A homily deve resumir o eixo espiritual da leitura.",
      "- O spiritualMeaning deve ser o bloco principal e respeitar claramente a profundidade escolhida.",
      "- A practicalApplication deve nascer dos trechos e dos temas preferidos, com uma ação concreta para o restante do dia.",
      "- A conclusion deve ser específica, não uma frase fixa reaproveitada.",
      "- A meditationQuestion deve ser nova em relação ao histórico recente.",
      "- Na sessão de um único trecho, practicalApplication e meditationQuestion devem avançar a homily do item. Não repita nem parafraseie as mesmas ideias ou frases."
    );
  }

  lines.push(
    "",
    "Reflexões recentes a não repetir (varie vocabulário e perguntas):",
    historyBlock,
    "",
    "Trechos escolhidos:",
    passageBlock,
    "",
    "Otimize para resposta rápida: seja completo, mas não prolixo."
  );

  return lines.join("\n");
}

function reasoningConfig() {
  const effort = trimText(process.env.OPENAI_REASONING_EFFORT || DEFAULT_REASONING_EFFORT, 20).toLowerCase();
  if (["off", "none", "disabled", "0"].includes(effort)) return undefined;
  return { effort };
}

async function callTextModel({ schema, schemaName, prompt, maxOutputTokens, debugContext = {} }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    const error = new Error("OPENAI_API_KEY is not configured");
    error.code = "missing_openai_api_key";
    error.statusCode = 503;
    throw error;
  }

  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Number(process.env.OPENAI_TIMEOUT_MS || DEFAULT_TIMEOUT_MS)
  );
  const baseURL = (process.env.OPENAI_BASE_URL || DEFAULT_TEXT_BASE_URL).replace(/\/$/, "");
  const model = process.env.OPENAI_MODEL || DEFAULT_MODEL;
  const formatName = safeSchemaName(schemaName);
  const reasoning = reasoningConfig();

  try {
    logAIDiagnostic("openai_request_start", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      clientID: debugContext.clientID,
      depth: debugContext.depth,
      tradition: debugContext.tradition,
      passagesCount: debugContext.passagesCount,
      promptLength: prompt.length,
      maxOutputTokens,
      reasoningEffort: reasoning?.effort,
      ...promptDebugDetails(prompt)
    });
    let response;
    try {
      response = await fetch(`${baseURL}/responses`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model,
          max_output_tokens: maxOutputTokens,
          ...(reasoning ? { reasoning } : {}),
          instructions: [
            buildSystemPrompt(),
            "Retorne somente JSON válido no formato solicitado.",
            "Não use markdown, comentários ou texto fora do JSON."
          ].join("\n"),
          input: prompt,
          text: {
            format: {
              type: "json_schema",
              name: formatName,
              schema,
              strict: true
            }
          }
        }),
        signal: controller.signal
      });
    } catch (error) {
      if (error?.name === "AbortError") {
        const timeoutError = new Error("OpenAI request timed out");
        timeoutError.code = "openai_timeout";
        timeoutError.statusCode = 504;
        throw timeoutError;
      }
      error.code = error.code || "openai_network_error";
      error.statusCode = error.statusCode || 502;
      throw error;
    }

    const data = await response.json().catch(() => null);
    if (!response.ok) {
      const error = new Error(data?.error?.message || `OpenAI request failed with ${response.status}`);
      error.code = classifyProviderError("openai", response.status, data);
      error.statusCode = response.status;
      throw error;
    }

    if (data?.status === "incomplete" && data?.incomplete_details?.reason === "max_output_tokens") {
      const error = new Error("OpenAI response was truncated by max_output_tokens");
      error.code = "openai_output_truncated";
      error.statusCode = 502;
      throw error;
    }

    const outputText = extractTextModelOutput(data);
    if (!outputText) {
      const error = new Error("OpenAI response did not include output text");
      error.code = "openai_empty_output";
      error.statusCode = 502;
      throw error;
    }

    try {
      const parsed = parseProviderJSON(outputText);
      logAIDiagnostic("openai_request_success", {
        endpoint: debugContext.endpoint,
        requestID: debugContext.requestID,
        depth: debugContext.depth,
        outputLength: outputText.length
      });
      return parsed;
    } catch (error) {
      error.code = "openai_json_parse_error";
      error.statusCode = 502;
      throw error;
    }
  } finally {
    clearTimeout(timeout);
  }
}

async function callElevenLabsSpeech({ input, voice, speed, debugContext = {} }) {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    const error = new Error("ELEVENLABS_API_KEY is not configured");
    error.code = "missing_elevenlabs_api_key";
    error.statusCode = 503;
    throw error;
  }

  const cleanInput = normalizeSpeechInput(input);
  if (!cleanInput) {
    const error = new Error("Speech input is empty");
    error.code = "empty_speech_input";
    error.statusCode = 400;
    throw error;
  }
  const speechSpeed = normalizeTTSSpeed(speed ?? process.env.ELEVENLABS_TTS_SPEED ?? DEFAULT_TTS_SPEED);
  const voiceID = trimText(voice || process.env.ELEVENLABS_VOICE_ID || DEFAULT_TTS_VOICE_ID, 160);
  const model = process.env.ELEVENLABS_TTS_MODEL || DEFAULT_TTS_MODEL;

  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Number(process.env.ELEVENLABS_TTS_TIMEOUT_MS || DEFAULT_TIMEOUT_MS)
  );

  try {
    logAIDiagnostic("elevenlabs_tts_request_start", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      clientID: debugContext.clientID,
      inputLength: cleanInput.length,
      ttsModel: model,
      voiceID,
      speed: speechSpeed
    });

    let response;
    try {
      response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceID)}?output_format=mp3_44100_128`, {
        method: "POST",
        headers: {
          "xi-api-key": apiKey,
          "Content-Type": "application/json",
          Accept: "audio/mpeg"
        },
        body: JSON.stringify({
          text: cleanInput,
          model_id: model,
          language_code: "pt",
          voice_settings: {
            stability: 0.58,
            similarity_boost: 0.76,
            style: 0.12,
            use_speaker_boost: false,
            speed: speechSpeed
          }
        }),
        signal: controller.signal
      });
    } catch (error) {
      if (error?.name === "AbortError") {
        const timeoutError = new Error("ElevenLabs TTS request timed out");
        timeoutError.code = "elevenlabs_tts_timeout";
        timeoutError.statusCode = 504;
        throw timeoutError;
      }
      error.code = error.code || "elevenlabs_tts_network_error";
      error.statusCode = error.statusCode || 502;
      throw error;
    }

    if (!response.ok) {
      const data = await response.json().catch(() => null);
      const error = new Error(data?.detail?.message || data?.error?.message || `ElevenLabs TTS request failed with ${response.status}`);
      error.code = classifyProviderError("elevenlabs_tts", response.status, data);
      error.statusCode = response.status;
      throw error;
    }

    const audio = Buffer.from(await response.arrayBuffer());
    if (!audio.length) {
      const error = new Error("ElevenLabs TTS response was empty");
      error.code = "elevenlabs_tts_empty_output";
      error.statusCode = 502;
      throw error;
    }

    logAIDiagnostic("elevenlabs_tts_request_success", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      outputBytes: audio.length
    });
    return audio;
  } finally {
    clearTimeout(timeout);
  }
}

function azureSpeechVoice() {
  return trimText(process.env.AZURE_SPEECH_VOICE || DEFAULT_AZURE_SPEECH_VOICE, 160);
}

function normalizeAzureProsodyPercent(value, fallback) {
  const normalized = String(value ?? "").trim();
  return /^[+-]?\d+(?:\.\d+)?%$/.test(normalized) ? normalized : fallback;
}

function normalizeAzureBreakMS(value, fallback = DEFAULT_AZURE_SPEECH_BREAK_MS) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(0, Math.min(5000, Math.round(parsed)));
}

// Fonte única dos parâmetros efetivos do SSML. Overrides existem somente para
// a prévia A/B local; produção, endpoint e prewarm usam os envs/defaults daqui.
function azureSpeechTone(overrides = {}) {
  const has = (key) => Object.prototype.hasOwnProperty.call(overrides, key);
  const rate = normalizeAzureProsodyPercent(
    has("rate") ? overrides.rate : process.env.AZURE_SPEECH_RATE,
    DEFAULT_AZURE_SPEECH_RATE
  );
  const pitchSource = has("pitch") ? overrides.pitch : process.env.AZURE_SPEECH_PITCH;
  const pitch = pitchSource === null || pitchSource === false
    ? null
    : normalizeAzureProsodyPercent(pitchSource, DEFAULT_AZURE_SPEECH_PITCH);
  const breakMs = normalizeAzureBreakMS(
    has("breakMs") ? overrides.breakMs : process.env.AZURE_SPEECH_BREAK_MS
  );
  const proclaimReference = has("proclaimReference") ? Boolean(overrides.proclaimReference) : true;
  const referenceSpeechVersion = String(
    has("referenceSpeechVersion")
      ? overrides.referenceSpeechVersion
      : proclaimReference ? AZURE_REFERENCE_SPEECH_VERSION : "legacy"
  );
  const signature = [
    `rate:${rate}`,
    `pitch:${pitch || "none"}`,
    `break:${breakMs}`,
    `ref-speech:${referenceSpeechVersion}`
  ].join("|");

  return { rate, pitch, breakMs, proclaimReference, referenceSpeechVersion, signature };
}

function normalizeTTSProvider(value = process.env.TTS_PROVIDER) {
  return String(value || "azure").trim().toLowerCase() === "elevenlabs" ? "elevenlabs" : "azure";
}

// Contrato de cache para trechos do catálogo. App, endpoint e pré-aquecimento
// usam exatamente "{reference}.\n{text}"; nenhum dado da sessão pode entrar aqui.
function canonicalPassageNarrationText(reference, text) {
  const canonicalReference = trimText(reference, 500);
  const canonicalText = trimText(text, 12000);
  if (!canonicalReference || !canonicalText) {
    const error = new Error("Passage reference and text are required for narration");
    error.code = "invalid_passage_narration_input";
    error.statusCode = 400;
    throw error;
  }
  return `${canonicalReference}.\n${canonicalText}`;
}

function parsedSpokenReference(reference) {
  const original = String(reference ?? "");
  const normalized = original.trim();
  if (!normalized) return { recognized: false, kind: "unknown", value: original };

  const withSpokenSlash = normalized.replace(/\s*\/\s*/g, ", ");
  const verseMatch = withSpokenSlash.match(/^(.+?\s+\d+)\s*[,:]\s*(\d+)(?:\s*-\s*(\d+))?$/);
  if (verseMatch) {
    const [, bookAndChapter, firstVerse, lastVerse] = verseMatch;
    return {
      recognized: true,
      kind: "verse",
      value: lastVerse
        ? `${bookAndChapter}, versículos ${firstVerse} a ${lastVerse}`
        : `${bookAndChapter}, versículo ${firstVerse}`
    };
  }

  const isChapterOnly = !/[,:]/.test(normalized) && /^.+\s+\d+$/.test(normalized);
  const isSlashChapterOnly = normalized.includes("/") && /^.+\s*\/\s*.+\s+\d+$/.test(normalized);
  if (isChapterOnly || isSlashChapterOnly) {
    return { recognized: true, kind: "chapter", value: withSpokenSlash };
  }

  return { recognized: false, kind: "unknown", value: original };
}

// A pausa das referências só de capítulo foi corrigida depois do primeiro
// prewarm. Marcar apenas esses textos evita reaproveitar os quatro MP3 antigos
// sem invalidar o restante do catálogo. Toda mudança futura que altere o som
// de um subconjunto deve ganhar um marcador equivalente na chave do cache.
function azureSpeechCadence(input, tone = azureSpeechTone()) {
  const cleanInput = normalizeSpeechInput(input);
  const canonicalMatch = cleanInput.match(/^([^\n]+)\.\n([\s\S]+)$/);
  if (!canonicalMatch || !tone.proclaimReference) return tone.signature;

  const proclaimed = parsedSpokenReference(canonicalMatch[1]);
  return proclaimed.kind === "chapter"
    ? `${tone.signature}|chapter-break-fix:v1`
    : tone.signature;
}

// Ajusta somente a forma falada. Referência exibida, texto canônico e hash do
// cache continuam recebendo a string original sem qualquer transformação.
function spokenReference(reference) {
  return parsedSpokenReference(reference).value;
}

function escapeXML(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function buildAzureSpeechSSML(input, voice = azureSpeechVoice(), toneOverrides = {}) {
  const cleanInput = normalizeSpeechInput(input);
  if (!cleanInput) {
    const error = new Error("Speech input is empty");
    error.code = "empty_speech_input";
    error.statusCode = 400;
    throw error;
  }

  const tone = azureSpeechTone(toneOverrides);
  const canonicalMatch = cleanInput.match(/^([^\n]+)\.\n([\s\S]+)$/);
  let spokenContent = escapeXML(cleanInput);
  if (canonicalMatch && tone.proclaimReference) {
    const [, reference, passageText] = canonicalMatch;
    const proclaimed = parsedSpokenReference(reference);
    if (proclaimed.recognized) {
      const pause = tone.breakMs > 0 ? `<break time='${tone.breakMs}ms'/>` : " ";
      spokenContent = `${escapeXML(proclaimed.value)}.${pause}${escapeXML(passageText)}`;
    }
  }
  const pitchAttribute = tone.pitch ? ` pitch='${escapeXML(tone.pitch)}'` : "";

  return `<speak version='1.0' xml:lang='pt-BR'><voice name='${escapeXML(voice)}'><prosody rate='${escapeXML(tone.rate)}'${pitchAttribute}>${spokenContent}</prosody></voice></speak>`;
}

async function callAzureSpeech({ input, speed, tone: toneOverrides = {}, debugContext = {} }) {
  const apiKey = process.env.AZURE_SPEECH_KEY;
  const region = trimText(process.env.AZURE_SPEECH_REGION || "", 80);
  if (!apiKey || !region) {
    const error = new Error("AZURE_SPEECH_KEY and AZURE_SPEECH_REGION must be configured");
    error.code = "missing_azure_speech_config";
    error.statusCode = 503;
    throw error;
  }

  const voice = azureSpeechVoice();
  const cleanInput = normalizeSpeechInput(input);
  const tone = azureSpeechTone(toneOverrides);
  const ssml = buildAzureSpeechSSML(cleanInput, voice, tone);
  // A velocidade recebida é mantida apenas para diagnóstico. A Azure usa o tom
  // efetivo do servidor no SSML, sem herdar o valor enviado pelo cliente iOS.
  const requestedSpeed = normalizeTTSSpeed(speed ?? DEFAULT_TTS_SPEED);
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Number(process.env.AZURE_SPEECH_TIMEOUT_MS || DEFAULT_TIMEOUT_MS)
  );

  try {
    logAIDiagnostic("azure_tts_request_start", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      clientID: debugContext.clientID,
      inputLength: cleanInput.length,
      voice,
      rate: tone.rate,
      pitch: tone.pitch,
      breakMs: tone.breakMs,
      referenceSpeechVersion: tone.referenceSpeechVersion,
      requestedSpeed
    });

    let response;
    try {
      response = await fetch(`https://${region}.tts.speech.microsoft.com/cognitiveservices/v1`, {
        method: "POST",
        headers: {
          "Ocp-Apim-Subscription-Key": apiKey,
          "Content-Type": "application/ssml+xml",
          "X-Microsoft-OutputFormat": "audio-24khz-160kbitrate-mono-mp3",
          "User-Agent": "Limiar",
          Accept: "audio/mpeg"
        },
        body: ssml,
        signal: controller.signal
      });
    } catch (error) {
      if (error?.name === "AbortError") {
        const timeoutError = new Error("Azure Speech request timed out");
        timeoutError.code = "azure_tts_timeout";
        timeoutError.statusCode = 504;
        throw timeoutError;
      }
      error.code = error.code || "azure_tts_network_error";
      error.statusCode = error.statusCode || 502;
      throw error;
    }

    if (!response.ok) {
      const responseText = await response.text().catch(() => "");
      let data;
      try {
        data = JSON.parse(responseText);
      } catch {
        data = { error: { message: responseText } };
      }
      const error = new Error(data?.error?.message || responseText || `Azure Speech request failed with ${response.status}`);
      error.code = classifyProviderError("azure_tts", response.status, data);
      error.statusCode = response.status;
      throw error;
    }

    const audio = Buffer.from(await response.arrayBuffer());
    if (!audio.length) {
      const error = new Error("Azure Speech response was empty");
      error.code = "azure_tts_empty_output";
      error.statusCode = 502;
      throw error;
    }

    logAIDiagnostic("azure_tts_request_success", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      outputBytes: audio.length,
      voice
    });
    return audio;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeSpeechInput(value) {
  return trimText(value, 12000)
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/[`*_#{}\[\]]/g, " ")
    .replace(/^\s*>\s?/gm, "")
    .replace(/\b[a-zA-Z]+_[a-zA-Z0-9_]+\b/g, " ")
    .replace(/^\s*[-•]\s*/gm, "")
    .replace(/\s+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]{2,}/g, " ")
    .trim();
}

function normalizeTTSSpeed(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return DEFAULT_TTS_SPEED;
  return Math.min(1.1, Math.max(0.75, parsed));
}

function classifyProviderError(prefix, status, data) {
  const message = String(data?.error?.message || "").toLowerCase();
  const type = String(data?.error?.type || "").toLowerCase();
  const code = String(data?.error?.code || "").toLowerCase();

  if (status === 401 || status === 403) return `${prefix}_auth_error`;
  if (status === 408 || status === 504) return `${prefix}_timeout`;
  if (message.includes("model") || type.includes("model") || code.includes("model")) {
    return `${prefix}_model_error`;
  }
  if (status === 429) return `${prefix}_rate_limited`;
  return `${prefix}_api_error`;
}

function logAIError(endpoint, error, context = {}) {
  console.error("limiar_ai_error", {
    endpoint,
    code: error.code || "ai_unknown_error",
    statusCode: error.statusCode || 502,
    message: error.message,
    requestID: context.requestID,
    clientID: context.clientID,
    ...(endpoint === "speech" ? providerInfo("tts_error") : providerInfo())
  });
}

function safeSchemaName(value) {
  return trimText(value, 80).replace(/[^a-zA-Z0-9_-]/g, "_") || "limiar_response";
}

function extractTextModelOutput(response) {
  if (typeof response?.output_text === "string") return response.output_text.trim();
  const output = response?.output;
  if (Array.isArray(output)) {
    const text = output
      .flatMap((item) => (Array.isArray(item?.content) ? item.content : []))
      .map((part) => {
        if (typeof part?.text === "string") return part.text;
        if (typeof part?.content === "string") return part.content;
        if (typeof part?.value === "string") return part.value;
        return "";
      })
      .join("")
      .trim();
    if (text) return text;
  }
  return extractChatCompletionText(response);
}

function extractChatCompletionText(response) {
  const content = response?.choices?.[0]?.message?.content;
  if (typeof content === "string") return content.trim();
  if (Array.isArray(content)) {
    return content
      .map((part) => (typeof part?.text === "string" ? part.text : ""))
      .join("")
      .trim();
  }
  return "";
}

function parseProviderJSON(text) {
  const raw = trimText(text, 50000);
  const withoutFence = raw
    .replace(/^```(?:json)?\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();
  try {
    return JSON.parse(withoutFence);
  } catch {
    const firstBrace = withoutFence.indexOf("{");
    const lastBrace = withoutFence.lastIndexOf("}");
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return JSON.parse(withoutFence.slice(firstBrace, lastBrace + 1));
    }
    throw new Error("provider_json_parse_failed");
  }
}

function validationError(code, message) {
  const error = new Error(message || code);
  error.code = code;
  error.statusCode = 502;
  return error;
}

function validateExplanationFields(value, context = "item") {
  if (!value || typeof value !== "object") {
    throw validationError("invalid_explanation", `AI returned an invalid ${context}`);
  }
  const clean = {};
  for (const key of explanationFieldsSchema.required) {
    if (!nonEmpty(value[key])) {
      throw validationError(`missing_${key}`, `AI ${context} is missing ${key}`);
    }
    clean[key] = trimText(value[key], 3000);
  }
  return clean;
}

function validateExplanationItems(value, expectedItemCount) {
  if (!value || !Array.isArray(value.items)) {
    throw validationError("invalid_items", "AI response did not include items");
  }
  if (value.items.length < expectedItemCount) {
    throw validationError("unexpected_item_count", "AI returned fewer items than expected");
  }
  return value.items
    .slice(0, expectedItemCount)
    .map((item, index) => validateExplanationFields(item, `item ${index + 1}`));
}

// Monta os itens finais da resposta: versículo vem do trecho selecionado
// (fonte da verdade), explicações vêm da IA. Campos extras (passageID, book,
// section, theme) são opcionais e ignorados por clientes antigos.
function assembleReadingItems(selectedPassages, explanations) {
  return selectedPassages.map((passage, index) => ({
    reference: passage.reference,
    passageText: passage.text,
    passageID: passage.id || undefined,
    book: passage.book || undefined,
    section: passage.section || undefined,
    theme: passage.theme || undefined,
    ...explanations[index]
  }));
}

function assembleReflection(selectedPassages, explanation) {
  return {
    reference: selectedPassages.map((passage) => passage.reference).join(" + "),
    passageText: selectedPassages
      .map((passage) => `${passage.reference}: ${passage.text}`)
      .join("\n\n"),
    ...explanation
  };
}

function selectionSeed(context = {}) {
  const day = new Date().toISOString().slice(0, 10);
  return `${day}|${context.clientID || "anonymous"}`;
}

module.exports = {
  DEFAULT_MODEL,
  DEFAULT_REASONING_EFFORT,
  DEFAULT_TTS_MODEL,
  DEFAULT_TTS_VOICE_ID,
  DEFAULT_TTS_SPEED,
  AZURE_REFERENCE_SPEECH_VERSION,
  DEFAULT_AZURE_SPEECH_BREAK_MS,
  DEFAULT_AZURE_SPEECH_PITCH,
  DEFAULT_AZURE_SPEECH_RATE,
  DEFAULT_AZURE_SPEECH_VOICE,
  SESSION_ITEM_COUNT,
  applyAudioHeaders,
  applyCommonHeaders,
  assembleReadingItems,
  assembleReflection,
  buildExplanationPrompt,
  callTextModel,
  callAzureSpeech,
  callElevenLabsSpeech,
  azureSpeechCadence,
  azureSpeechVoice,
  azureSpeechTone,
  buildAzureSpeechSSML,
  canonicalPassageNarrationText,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  explanationFieldsSchema,
  logAIDiagnostic,
  logAIError,
  normalizeSpeechInput,
  normalizeTTSProvider,
  normalizeTTSSpeed,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  normalizeContentIdentity,
  resolveReadingSessionOptions,
  parseProviderJSON,
  parseBody,
  readingSessionExplanationSchema,
  reflectionExplanationSchema,
  requirePost,
  selectSessionPassages,
  selectionSeed,
  spokenReference,
  spiritualReadingExplanationSchema,
  validateExplanationFields,
  validateExplanationItems
};
