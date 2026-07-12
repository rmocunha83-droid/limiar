const crypto = require("node:crypto");
const {
  DEFAULT_TTS_MODEL,
  DEFAULT_TTS_SPEED,
  DEFAULT_TTS_VOICE_ID,
  DEFAULT_AZURE_SPEECH_RATE,
  applyAudioHeaders,
  applyCommonHeaders,
  azureSpeechVoice,
  callAzureSpeech,
  callElevenLabsSpeech,
  enforceAIRateLimit,
  logAIDiagnostic,
  logAIError,
  parseBody,
  requirePost,
  normalizeTTSProvider,
  normalizeTTSSpeed
} = require("./_limiar-ai");

// Cache de áudio no Vercel Blob: cada combinação texto+voz+velocidade+modelo é
// sintetizada uma única vez. Requer o env BLOB_READ_WRITE_TOKEN (criado
// automaticamente ao conectar um Blob Store ao projeto). Sem o token, o
// endpoint funciona como antes, sintetizando a cada chamada.
function speechConfig(body) {
  const provider = normalizeTTSProvider();
  if (provider === "azure") {
    // O app publicado ainda envia uma voz do ElevenLabs. No Azure ela nunca é
    // reutilizada: somente AZURE_SPEECH_VOICE define a voz efetiva.
    return {
      provider,
      voice: azureSpeechVoice(),
      speed: DEFAULT_AZURE_SPEECH_RATE,
      model: "azure-speech"
    };
  }

  // voice e speed vêm do cliente neste caminho: normalizamos antes de compor a
  // chave de cache (voz sem espaços, velocidade numérica limitada) para que um
  // valor forjado não consiga colidir com a chave de outro texto legítimo.
  const rawVoice = String(body.voice || process.env.ELEVENLABS_VOICE_ID || DEFAULT_TTS_VOICE_ID);
  return {
    provider,
    voice: rawVoice.replace(/\s+/g, "").slice(0, 80),
    speed: String(normalizeTTSSpeed(body.speed ?? process.env.ELEVENLABS_TTS_SPEED ?? DEFAULT_TTS_SPEED)),
    model: String(process.env.ELEVENLABS_TTS_MODEL || DEFAULT_TTS_MODEL).replace(/\s+/g, "").slice(0, 80)
  };
}

function cacheKey(body, config = speechConfig(body)) {
  const digest = crypto
    .createHash("sha256")
    .update([config.provider, config.model, config.voice, config.speed, String(body.text || "")].join(" "))
    .digest("hex");
  return `tts/${digest}.mp3`;
}

function blobEnabled() {
  // Projetos conectados pelo fluxo atual do Vercel Blob usam OIDC e recebem
  // BLOB_STORE_ID em vez de um token estático. O SDK reconhece ambos os
  // modos; manter o token aqui preserva compatibilidade com conexões antigas.
  return Boolean(process.env.BLOB_READ_WRITE_TOKEN || process.env.BLOB_STORE_ID);
}

async function findCachedAudio(pathname, debugContext) {
  try {
    const { head } = require("@vercel/blob");
    const existing = await head(pathname);
    return existing?.url || null;
  } catch (error) {
    if (error?.name === "BlobNotFoundError") return null;
    // console.warn: precisa aparecer em produção — cache degradado dobra o
    // custo de síntese em silêncio se o aviso ficar restrito ao modo debug.
    console.warn("limiar_tts_cache_lookup_failed", { ...debugContext, error: String(error?.message || error) });
    return null;
  }
}

async function storeCachedAudio(pathname, audio, debugContext) {
  try {
    const { put } = require("@vercel/blob");
    await put(pathname, audio, {
      access: "public",
      addRandomSuffix: false,
      contentType: "audio/mpeg",
      cacheControlMaxAge: 60 * 60 * 24 * 365
    });
    logAIDiagnostic("tts_cache_stored", { ...debugContext, pathname, bytes: audio.length });
    return true;
  } catch (error) {
    console.warn("limiar_tts_cache_store_failed", { ...debugContext, error: String(error?.message || error) });
    if (debugContext?.throwOnCacheError) throw error;
    return false;
  }
}

async function handler(req, res) {
  applyCommonHeaders(res);
  if (!requirePost(req, res)) return;
  const rateLimit = enforceAIRateLimit(req, res, "speech");
  if (!rateLimit.allowed) return;

  try {
    const body = parseBody(req);
    const debugContext = {
      endpoint: "speech",
      requestID: rateLimit.context.requestID,
      clientID: rateLimit.context.clientID
    };

    const config = speechConfig(body);
    const pathname = cacheKey(body, config);
    if (blobEnabled()) {
      const cachedURL = await findCachedAudio(pathname, debugContext);
      if (cachedURL) {
        logAIDiagnostic("tts_cache_hit", { ...debugContext, pathname });
        res.statusCode = 302;
        res.setHeader("Location", cachedURL);
        res.end();
        return;
      }
    }

    const audio = config.provider === "azure"
      ? await callAzureSpeech({ input: body.text, speed: config.speed, debugContext })
      : await callElevenLabsSpeech({
        input: body.text,
        voice: config.voice,
        speed: config.speed,
        debugContext
      });

    if (blobEnabled()) {
      await storeCachedAudio(pathname, audio, debugContext);
    }

    applyAudioHeaders(res);
    res.statusCode = 200;
    res.end(audio);
  } catch (error) {
    logAIError("speech", error, rateLimit.context);
    applyCommonHeaders(res);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_speech_failed" }));
  }
}

module.exports = handler;
// O script de pré-aquecimento reutiliza estes helpers para gerar exatamente a
// mesma chave e o mesmo áudio atendidos pelo endpoint HTTP.
module.exports.blobEnabled = blobEnabled;
module.exports.cacheKey = cacheKey;
module.exports.findCachedAudio = findCachedAudio;
module.exports.speechConfig = speechConfig;
module.exports.storeCachedAudio = storeCachedAudio;
