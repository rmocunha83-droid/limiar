#!/usr/bin/env node

const passages = require("../Limiar/Resources/passages.json");
const {
  callAzureSpeech,
  canonicalPassageNarrationText
} = require("../api/_limiar-ai");
const {
  cacheKey,
  findCachedAudio,
  speechConfig,
  storeCachedAudio
} = require("../api/speech");

const REQUIRED_ENV = ["AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION", "BLOB_READ_WRITE_TOKEN"];
const delay = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function requireConfiguration() {
  const missing = REQUIRED_ENV.filter((name) => !String(process.env[name] || "").trim());
  if (missing.length) {
    throw new Error(`Pré-aquecimento exige as variáveis: ${missing.join(", ")}`);
  }
}

function prewarmConcurrency() {
  const requested = Number(process.env.PREWARM_CONCURRENCY || 4);
  return Math.max(3, Math.min(5, Number.isFinite(requested) ? Math.floor(requested) : 4));
}

function isTransient(error) {
  const statusCode = Number(error?.statusCode || 0);
  return statusCode === 408 || statusCode === 429 || statusCode >= 500 || error?.name === "AbortError";
}

async function prewarmPassage(passage, stats) {
  const text = canonicalPassageNarrationText(passage.reference, passage.text);
  const config = speechConfig({ text });
  const pathname = cacheKey({ text }, config);
  const debugContext = { endpoint: "prewarm_narration", passageID: passage.id };

  if (await findCachedAudio(pathname, debugContext)) {
    stats.existing += 1;
    return;
  }

  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const audio = await callAzureSpeech({ input: text, debugContext });
      await storeCachedAudio(pathname, audio, { ...debugContext, throwOnCacheError: true });
      stats.generated += 1;
      return;
    } catch (error) {
      if (attempt === 0 && isTransient(error)) {
        await delay(700);
        continue;
      }
      stats.failures.push({ id: passage.id, error: String(error?.message || error) });
      return;
    }
  }
}

async function main() {
  requireConfiguration();
  const stats = { total: passages.length, existing: 0, generated: 0, failures: [] };
  const concurrency = prewarmConcurrency();
  let cursor = 0;

  async function worker() {
    while (cursor < passages.length) {
      const passage = passages[cursor++];
      await prewarmPassage(passage, stats);
      await delay(120);
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
  console.log(JSON.stringify({
    total: stats.total,
    alreadyExisting: stats.existing,
    generated: stats.generated,
    failures: stats.failures.length,
    failedIDs: stats.failures.map((failure) => failure.id)
  }, null, 2));
  if (stats.failures.length) process.exitCode = 1;
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { prewarmConcurrency, requireConfiguration };
