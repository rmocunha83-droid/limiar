const DEFAULT_MODEL = "gpt-4.1-mini";
const DEFAULT_TTS_MODEL = "gpt-4o-mini-tts";
const DEFAULT_TTS_VOICE = "coral";
const DEFAULT_TTS_SPEED = 0.92;
const DEFAULT_TIMEOUT_MS = 12000;
const DEFAULT_RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const DEFAULT_RATE_LIMIT_MAX_REQUESTS = 24;
const rateLimitBuckets = globalThis.__limiarAIRateLimitBuckets || new Map();
globalThis.__limiarAIRateLimitBuckets = rateLimitBuckets;

const reflectionSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    reference: { type: "string" },
    passageText: { type: "string" },
    homily: { type: "string" },
    spiritualMeaning: { type: "string" },
    practicalApplication: { type: "string" },
    conclusion: { type: "string" },
    meditationQuestion: { type: "string" }
  },
  required: [
    "reference",
    "passageText",
    "homily",
    "spiritualMeaning",
    "practicalApplication",
    "conclusion",
    "meditationQuestion"
  ]
};

const spiritualReadingSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    items: {
      type: "array",
      minItems: 1,
      maxItems: 8,
      items: reflectionSchema
    }
  },
  required: ["items"]
};

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

function enforceAIRateLimit(req, res, endpoint) {
  const context = requestContext(req, endpoint);
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
    favoriteBooks: compactList(profile.favoriteBooks, 12),
    favoriteBookIDs: compactList(profile.favoriteBookIDs, 12),
    favoriteThemes: compactList(profile.favoriteThemes, 12),
    favoriteThemeIDs: compactList(profile.favoriteThemeIDs, 12),
    explanationDepth: normalizeDepth(profile.explanationDepth),
    avoidedSections: compactList(profile.avoidedSections, 8),
    avoidedBooks: compactList(profile.avoidedBooks, 12),
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

function depthGuidance(depth) {
  if (depth === "curta") {
    return [
      "Profundidade curta:",
      "- homily: 1 parágrafo breve com 2 frases no máximo;",
      "- spiritualMeaning: 1 parágrafo objetivo, direto ao sentido espiritual central;",
      "- practicalApplication e conclusion: 1 frase cada, concreta e sem rodeio;",
      "- meditationQuestion: pergunta curta."
    ].join("\n");
  }
  if (depth === "grande") {
    return [
      "Profundidade mais profunda:",
      "- homily: 2 a 3 parágrafos desenvolvidos, com contexto do trecho e ligação com a tradição;",
      "- spiritualMeaning: explique com mais densidade espiritual, conectando trecho, tema preferido e vida concreta;",
      "- practicalApplication: aplicação prática mais elaborada, sem moralismo, com uma decisão clara para o próximo período;",
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

function depthOutputTokenLimit(depth, endpoint) {
  const isReading = endpoint === "spiritual-reading";
  if (depth === "curta") return isReading ? 1800 : 700;
  if (depth === "grande") return isReading ? 4200 : 1800;
  return isReading ? 2800 : 1100;
}

function diagnosticEnabled() {
  return process.env.LIMIAR_AI_DEBUG === "1" || process.env.NODE_ENV !== "production";
}

function logAIDiagnostic(event, details = {}) {
  if (!diagnosticEnabled()) return;
  console.info("limiar_ai_diagnostic", {
    event,
    ...details,
    model: process.env.OPENAI_MODEL || DEFAULT_MODEL
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
    .slice(0, 8);
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

function buildSystemPrompt() {
  return [
    "Você é o motor de reflexão espiritual do app Limiar.",
    "Gere conteúdo em português do Brasil, com tom acolhedor, sóbrio e pastoral.",
    "Não invente texto bíblico ou religioso: use apenas os trechos enviados.",
    "Respeite a tradição informada. Para tradição judaica, não use Novo Testamento. Para espírita, use tom moral e de reforma íntima.",
    "Evite diagnóstico médico, aconselhamento clínico, promessas espirituais absolutas ou linguagem de autoridade religiosa institucional.",
    "Não inclua identificadores pessoais. Responda somente no JSON solicitado."
  ].join("\n");
}

function buildContextPrompt({ profile, passages, recentPassageIDs = [], recentReflections = [] }) {
  const passageBlock = passages
    .map((passage, index) => {
      return [
        `Trecho ${index + 1}`,
        `Referência: ${passage.reference}`,
        `Título: ${passage.title}`,
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

  return [
    "Preferências atuais do usuário. Use estas escolhas como regras de personalização, não como contexto opcional:",
    `Tradição: ${profile.tradition}${profile.traditionID ? ` [${profile.traditionID}]` : ""}`,
    `Profundidade: ${profile.explanationDepth}`,
    depthGuidance(profile.explanationDepth),
    `Seções preferidas: ${profile.favoriteSections.join(", ") || "não informado"}`,
    `IDs das seções preferidas: ${profile.favoriteSectionIDs.join(", ") || "não informado"}`,
    `Livros preferidos: ${profile.favoriteBooks.join(", ") || "não informado"}`,
    `IDs dos livros preferidos: ${profile.favoriteBookIDs.join(", ") || "não informado"}`,
    `Temas preferidos: ${profile.favoriteThemes.join(", ") || "não informado"}`,
    `IDs dos temas preferidos: ${profile.favoriteThemeIDs.join(", ") || "não informado"}`,
    `Evitar seções incompatíveis: ${profile.avoidedSections.join(", ") || "não informado"}`,
    `Evitar livros incompatíveis: ${profile.avoidedBooks.join(", ") || "não informado"}`,
    `Diretriz de tom da tradição: ${profile.toneGuidance || "não informado"}`,
    "",
    "Regras obrigatórias de personalização:",
    "- Priorize o sentido espiritual dos trechos enviados que combinem com os livros, seções e temas preferidos.",
    "- Integre pelo menos um tema preferido quando houver temas informados, de forma natural e coerente.",
    "- A profundidade escolhida deve mudar visivelmente o tamanho, a densidade e a aplicação prática.",
    "- Nunca use livros ou seções marcados como incompatíveis para a tradição.",
    "- Evite respostas genéricas que funcionariam igualmente para qualquer tradição, tema ou profundidade.",
    `Trechos recentes a evitar: ${compactList(recentPassageIDs, 20).join(", ") || "não informado"}`,
    "Reflexões recentes a não repetir:",
    historyBlock,
    "",
    "Trechos disponíveis:",
    passageBlock
  ].join("\n");
}

async function callOpenAI({ schema, schemaName, prompt, maxOutputTokens, debugContext = {} }) {
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

  try {
    logAIDiagnostic("openai_request_start", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      clientID: debugContext.clientID,
      depth: debugContext.depth,
      tradition: debugContext.tradition,
      favoriteThemesCount: debugContext.favoriteThemesCount,
      favoriteBooksCount: debugContext.favoriteBooksCount,
      favoriteSectionsCount: debugContext.favoriteSectionsCount,
      passagesCount: debugContext.passagesCount,
      promptLength: prompt.length,
      maxOutputTokens,
      ...promptDebugDetails(prompt)
    });
    let response;
    try {
      response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: process.env.OPENAI_MODEL || DEFAULT_MODEL,
          store: false,
          max_output_tokens: maxOutputTokens,
          input: [
            { role: "system", content: buildSystemPrompt() },
            { role: "user", content: prompt }
          ],
          text: {
            format: {
              type: "json_schema",
              name: schemaName,
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
      error.code = classifyOpenAIError(response.status, data);
      error.statusCode = response.status;
      throw error;
    }

    const outputText = extractOutputText(data);
    if (!outputText) {
      const error = new Error("OpenAI response did not include output text");
      error.code = "openai_empty_output";
      error.statusCode = 502;
      throw error;
    }

    try {
      const parsed = JSON.parse(outputText);
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

async function callOpenAISpeech({ input, voice, instructions, speed, debugContext = {} }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    const error = new Error("OPENAI_API_KEY is not configured");
    error.code = "missing_openai_api_key";
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
  const speechSpeed = normalizeTTSSpeed(speed ?? process.env.OPENAI_TTS_SPEED ?? DEFAULT_TTS_SPEED);

  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Number(process.env.OPENAI_TTS_TIMEOUT_MS || DEFAULT_TIMEOUT_MS)
  );

  try {
    logAIDiagnostic("openai_tts_request_start", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      clientID: debugContext.clientID,
      inputLength: cleanInput.length,
      ttsModel: process.env.OPENAI_TTS_MODEL || DEFAULT_TTS_MODEL,
      voice: voice || process.env.OPENAI_TTS_VOICE || DEFAULT_TTS_VOICE,
      speed: speechSpeed
    });

    let response;
    try {
      response = await fetch("https://api.openai.com/v1/audio/speech", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model: process.env.OPENAI_TTS_MODEL || DEFAULT_TTS_MODEL,
          voice: voice || process.env.OPENAI_TTS_VOICE || DEFAULT_TTS_VOICE,
          input: cleanInput,
          instructions: trimText(instructions, 900)
            || "Narre em português do Brasil com voz calma, natural, acolhedora e ritmo contemplativo. Faça pausas discretas entre referência, trecho, explicação e aplicação prática.",
          response_format: "mp3",
          speed: speechSpeed
        }),
        signal: controller.signal
      });
    } catch (error) {
      if (error?.name === "AbortError") {
        const timeoutError = new Error("OpenAI TTS request timed out");
        timeoutError.code = "openai_tts_timeout";
        timeoutError.statusCode = 504;
        throw timeoutError;
      }
      error.code = error.code || "openai_tts_network_error";
      error.statusCode = error.statusCode || 502;
      throw error;
    }

    if (!response.ok) {
      const data = await response.json().catch(() => null);
      const error = new Error(data?.error?.message || `OpenAI TTS request failed with ${response.status}`);
      error.code = classifyOpenAIError(response.status, data);
      error.statusCode = response.status;
      throw error;
    }

    const audio = Buffer.from(await response.arrayBuffer());
    if (!audio.length) {
      const error = new Error("OpenAI TTS response was empty");
      error.code = "openai_tts_empty_output";
      error.statusCode = 502;
      throw error;
    }

    logAIDiagnostic("openai_tts_request_success", {
      endpoint: debugContext.endpoint,
      requestID: debugContext.requestID,
      outputBytes: audio.length
    });
    return audio;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeSpeechInput(value) {
  return trimText(value, 12000)
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/[`*_#>{}\[\]]/g, " ")
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

function classifyOpenAIError(status, data) {
  const message = String(data?.error?.message || "").toLowerCase();
  const type = String(data?.error?.type || "").toLowerCase();
  const code = String(data?.error?.code || "").toLowerCase();

  if (status === 401 || status === 403) return "openai_auth_error";
  if (status === 408 || status === 504) return "openai_timeout";
  if (message.includes("model") || type.includes("model") || code.includes("model")) {
    return "openai_model_error";
  }
  if (status === 429) return "openai_rate_limited";
  return "openai_api_error";
}

function logAIError(endpoint, error, context = {}) {
  console.error("limiar_ai_error", {
    endpoint,
    code: error.code || "ai_unknown_error",
    statusCode: error.statusCode || 502,
    message: error.message,
    requestID: context.requestID,
    clientID: context.clientID,
    model: process.env.OPENAI_MODEL || DEFAULT_MODEL
  });
}

function extractOutputText(response) {
  if (typeof response.output_text === "string") return response.output_text;
  const chunks = [];
  for (const item of response.output || []) {
    for (const content of item.content || []) {
      if (content.type === "output_text" && typeof content.text === "string") {
        chunks.push(content.text);
      }
    }
  }
  return chunks.join("").trim();
}

function validateReflection(value) {
  if (!value || typeof value !== "object") throw new Error("invalid_reflection");
  for (const key of reflectionSchema.required) {
    if (!nonEmpty(value[key])) throw new Error(`missing_${key}`);
    value[key] = trimText(value[key], 3000);
  }
  return value;
}

function validateSpiritualReading(value, expectedItemCount) {
  if (!value || !Array.isArray(value.items)) throw new Error("invalid_items");
  const maxItems = expectedItemCount || 8;
  const items = value.items.map(validateReflection).slice(0, maxItems);
  if (!items.length) throw new Error("empty_items");
  if (expectedItemCount && items.length !== expectedItemCount) {
    throw new Error("unexpected_item_count");
  }
  return { items };
}

module.exports = {
  DEFAULT_MODEL,
  DEFAULT_TTS_MODEL,
  DEFAULT_TTS_VOICE,
  DEFAULT_TTS_SPEED,
  applyAudioHeaders,
  applyCommonHeaders,
  buildContextPrompt,
  callOpenAI,
  callOpenAISpeech,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  logAIDiagnostic,
  logAIError,
  normalizeSpeechInput,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  parseBody,
  reflectionSchema,
  requirePost,
  spiritualReadingSchema,
  validateReflection,
  validateSpiritualReading
};
