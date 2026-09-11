const test = require("node:test");
const assert = require("node:assert/strict");
const blob = require("@vercel/blob");
const { findCachedAudio } = require("../api/speech");
const { requireConfiguration } = require("../scripts/prewarm_narration");

test("a real BlobNotFoundError is a cache miss, including strict mode", async (t) => {
  t.mock.method(blob, "head", async () => { throw new blob.BlobNotFoundError(); });
  assert.equal(await findCachedAudio("tts/test.mp3", { throwOnLookupError: true }), null);
});

test("strict prewarming stops on cache access failures", async (t) => {
  const failure = new Error("Access denied");
  t.mock.method(blob, "head", async () => { throw failure; });
  await assert.rejects(findCachedAudio("tts/test.mp3", { throwOnLookupError: true }), failure);
});

test("prewarming accepts existing OIDC Blob configuration without a static token", () => {
  const keys = ["AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION", "BLOB_STORE_ID", "BLOB_READ_WRITE_TOKEN", "TTS_PROVIDER"];
  const previous = Object.fromEntries(keys.map(key => [key, process.env[key]]));
  try {
    process.env.AZURE_SPEECH_KEY = "unit-test-only";
    process.env.AZURE_SPEECH_REGION = "brazilsouth";
    process.env.BLOB_STORE_ID = "unit-test-store";
    process.env.TTS_PROVIDER = "azure";
    delete process.env.BLOB_READ_WRITE_TOKEN;
    assert.doesNotThrow(requireConfiguration);
    delete process.env.BLOB_STORE_ID;
    assert.throws(requireConfiguration, /BLOB_READ_WRITE_TOKEN ou BLOB_STORE_ID/);
  } finally {
    for (const key of keys) {
      if (previous[key] === undefined) delete process.env[key];
      else process.env[key] = previous[key];
    }
  }
});
