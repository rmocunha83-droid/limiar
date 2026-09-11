#!/usr/bin/env node

const passages = require("../Limiar/Resources/passages.json");
const { parseArgs } = require("node:util");
const {
  callAzureSpeech,
  canonicalPassageNarrationText
} = require("../api/_limiar-ai");
const {
  blobEnabled,
  cacheKey,
  findCachedAudio,
  speechConfig,
  storeCachedAudio
} = require("../api/speech");

const REQUIRED_ENV = ["AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION"];
const delay = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function requireConfiguration() {
  const missing = REQUIRED_ENV.filter((name) => !String(process.env[name] || "").trim());
  if (!blobEnabled()) missing.push("BLOB_READ_WRITE_TOKEN ou BLOB_STORE_ID");
  if (missing.length) {
    throw new Error(`Pré-aquecimento exige as variáveis: ${missing.join(", ")}`);
  }
  if (String(process.env.TTS_PROVIDER || "azure").trim().toLowerCase() !== "azure") {
    throw new Error("Pré-aquecimento Azure exige TTS_PROVIDER=azure.");
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

async function prewarmPassage(passage, stats, checkOnly = false) {
  const text = canonicalPassageNarrationText(passage.reference, passage.text);
  const config = speechConfig({ text });
  const pathname = cacheKey({ text }, config);
  const debugContext = { endpoint: "prewarm_narration", throwOnLookupError: true };

  if (await findCachedAudio(pathname, debugContext)) {
    stats.existing += 1;
    return;
  }
  if (checkOnly) {
    stats.missing += 1;
    stats.missingCharacters += text.length;
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
  const { values } = parseArgs({ options: {
    "new-only": { type: "boolean", default: false },
    "check-only": { type: "boolean", default: false }
  } });
  requireConfiguration();
  const selected = values["new-only"] ? passages.filter(p => p.id.startsWith("blivre-2018-")) : passages;
  // Traditions can share identical canonical audio. Queue each cache key once.
  const unique = [...new Map(selected.map(p => {
    const text = canonicalPassageNarrationText(p.reference, p.text);
    return [cacheKey({ text }), p];
  })).values()];
  const stats = { total: selected.length, existing: 0, generated: 0, missing: 0, missingCharacters: 0, failures: [] };
  const concurrency = prewarmConcurrency();
  let cursor = 0;
  let fatalError;

  async function worker() {
    while (!fatalError && cursor < unique.length) {
      const passage = unique[cursor++];
      try {
        await prewarmPassage(passage, stats, values["check-only"]);
      } catch (error) {
        // Failed cache authentication must not launch more paid synthesis.
        fatalError = error;
        return;
      }
      await delay(120);
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
  if (fatalError) throw fatalError;
  console.log(JSON.stringify({
    total: stats.total,
    uniqueAudio: unique.length,
    checkOnly: values["check-only"],
    missing: stats.missing,
    missingCharacters: stats.missingCharacters,
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
