const DEFAULT_MODEL = "gpt-5.4-mini";
const DEFAULT_TEXT_BASE_URL = "https://api.openai.com/v1";
const DEFAULT_TTS_MODEL = "eleven_flash_v2_5";
const DEFAULT_TTS_VOICE_ID = "21m00Tcm4TlvDq8ikWAM";
const DEFAULT_TTS_SPEED = 0.92;
const DEFAULT_TIMEOUT_MS = 25000;
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

const readingSessionSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    items: spiritualReadingSchema.properties.items,
    reflection: reflectionSchema
  },
  required: ["items", "reflection"]
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

function depthOutputTokenLimit(depth, endpoint) {
  if (endpoint === "reading-session") {
    if (depth === "curta") return 1200;
    if (depth === "grande") return 3000;
    return 2100;
  }
  const isReading = endpoint === "spiritual-reading";
  if (depth === "curta") return isReading ? 900 : 500;
  if (depth === "grande") return isReading ? 2400 : 1300;
  return isReading ? 1600 : 850;
}

function diagnosticEnabled() {
  return process.env.LIMIAR_AI_DEBUG === "1" || process.env.NODE_ENV !== "production";
}

function logAIDiagnostic(event, details = {}) {
  if (!diagnosticEnabled()) return;
  console.info("limiar_ai_diagnostic", {
    event,
    ...details,
    provider: "openai",
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
    .slice(0, 24);
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
    `Trechos recentes a evitar, incluindo IDs e referências: ${compactList(recentPassageIDs, 40).join(", ") || "não informado"}`,
    "Reflexões recentes a não repetir:",
    historyBlock,
    "",
    "Trechos disponíveis:",
    passageBlock
  ].join("\n");
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
      response = await fetch(`${baseURL}/responses`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model,
          max_output_tokens: maxOutputTokens,
          instructions: [
            buildSystemPrompt(),
            `Retorne somente JSON válido compatível com o schema ${schemaName}.`,
            "Não use markdown, comentários ou texto fora do JSON."
          ].join("\n"),
          input: [
            prompt,
            "",
            `Schema esperado (${schemaName}):`,
            JSON.stringify(schema)
          ].join("\n"),
          text: {
            format: {
              type: "json_schema",
              name: formatName,
              schema,
              strict: false
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
  const isSpeech = endpoint === "speech";
  console.error("limiar_ai_error", {
    endpoint,
    code: error.code || "ai_unknown_error",
    statusCode: error.statusCode || 502,
    message: error.message,
    requestID: context.requestID,
    clientID: context.clientID,
    provider: isSpeech ? "elevenlabs" : "openai",
    model: isSpeech
      ? process.env.ELEVENLABS_TTS_MODEL || DEFAULT_TTS_MODEL
      : process.env.OPENAI_MODEL || DEFAULT_MODEL
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

function validateReadingSession(value, expectedItemCount) {
  if (!value || typeof value !== "object") throw new Error("invalid_reading_session");
  const reading = validateSpiritualReading(value, expectedItemCount);
  return {
    items: reading.items,
    reflection: validateReflection(value.reflection)
  };
}

module.exports = {
  DEFAULT_MODEL,
  DEFAULT_TTS_MODEL,
  DEFAULT_TTS_VOICE_ID,
  DEFAULT_TTS_SPEED,
  applyAudioHeaders,
  applyCommonHeaders,
  buildContextPrompt,
  callTextModel,
  callElevenLabsSpeech,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  logAIDiagnostic,
  logAIError,
  normalizeSpeechInput,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  parseProviderJSON,
  parseBody,
  reflectionSchema,
  readingSessionSchema,
  requirePost,
  spiritualReadingSchema,
  validateReflection,
  validateReadingSession,
  validateSpiritualReading
};
