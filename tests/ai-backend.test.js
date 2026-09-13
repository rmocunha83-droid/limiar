const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const {
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
  assembleReadingItems,
  assembleReflection,
  azureSpeechCadence,
  azureSpeechVoice,
  azureSpeechTone,
  buildExplanationPrompt,
  buildAzureSpeechSSML,
  canonicalPassageNarrationText,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  normalizeSpeechInput,
  normalizeTTSProvider,
  normalizePassages,
  normalizeProfile,
  pauseTurnGuidance,
  normalizeRecentReflections,
  safeAIDetails,
  logAIError,
  parseProviderJSON,
  readingSessionExplanationSchema,
  resolveReadingSessionOptions,
  selectSessionPassages,
  selectionSeed,
  spokenReference,
  validateExplanationFields,
  validateExplanationItems
} = require("../api/_limiar-ai");

test("AI diagnostics discard religious content and personal identifiers", () => {
  assert.deepEqual(safeAIDetails({ endpoint: "reading-session", durationMs: 100,
    outcome: "success", items: 2, tradition: "Católica", favoriteBooks: "Salmos",
    promptPreview: "conteúdo privado", clientID: "identificador", requestID: "id",
    message: "segredo", summary: "reflexão", statusCode: 200 }),
  { endpoint: "reading-session", durationMs: 100, outcome: "success", items: 2, statusCode: 200 });
  const previous = console.error;
  let output;
  console.error = (...args) => { output = JSON.stringify(args); };
  try { logAIError("reading-session", { code: "segredo", message: "privado" }, { clientID: "pessoa" }); }
  finally { console.error = previous; }
  assert.ok(!/segredo|privado|pessoa/.test(output));
});

test("explanation diversity is opt-in, bounded and keeps legacy prompts intact", () => {
  const history = normalizeRecentReflections([{ reference: "Salmo 23", summary: "Resumo",
    openings: ["Abertura anterior", "x".repeat(300)], applications: ["Aplicação anterior"] }]);
  assert.equal(history[0].openings[1].length, 180);
  const args = { profile: normalizeProfile({}), selectedPassages: [{ reference: "Salmo 1", text: "Texto" }], recentReflections: history, includeReflection: true };
  const legacy = buildExplanationPrompt(args);
  const enhanced = buildExplanationPrompt({ ...args, diversityVersion: 1, seed: "teste" });
  assert.ok(!legacy.includes("Abertura anterior"));
  assert.ok(enhanced.includes("Abertura anterior"));
  assert.ok(enhanced.includes("Aplicação anterior"));
  assert.ok(enhanced.includes("Não copie aberturas"));
  assert.ok(enhanced.includes("Texto: Texto"));
  assert.equal(buildExplanationPrompt({ ...args, diversityVersion: 0 }), legacy);
});

test("reading endpoint preserves old and new contracts with one provider call", async () => {
  const handler = require("../api/reading-session");
  const previousFetch = global.fetch;
  const previousKey = process.env.OPENAI_API_KEY;
  const previousSecret = process.env.LIMIAR_APP_SECRET;
  const previousInfo = console.info;
  const previousError = console.error;
  process.env.OPENAI_API_KEY = "unit-test-key";
  delete process.env.LIMIAR_APP_SECRET;
  const logs = [];
  console.info = (...args) => logs.push(args);
  console.error = (...args) => logs.push(args);
  const fields = { homily: "Explicação", spiritualMeaning: "Sentido", practicalApplication: "Aplicação", conclusion: "Conclusão", meditationQuestion: "Pergunta?" };
  let calls = 0;
  let fail = false;
  global.fetch = async () => {
    calls += 1;
    return fail ? { ok: false, status: 503, json: async () => ({ error: { message: "privado" } }) }
      : { ok: true, json: async () => ({ output_text: JSON.stringify({ items: [fields], reflection: fields }) }) };
  };
  try {
    for (const version of [undefined, 1]) {
      let response;
      const res = { setHeader() {}, end(value) { response = JSON.parse(value); } };
      await handler({ method: "POST", headers: { "x-limiar-client-id": `compat-${version}-${Date.now()}` }, body: {
        profile: { tradition: "Católica" }, passages: [{ id: "test", reference: "Salmo 1", text: "Canônico" }],
        itemCount: 1, explanationDiversityVersion: version } }, res);
      assert.equal(res.statusCode, 200);
      assert.equal(response.items[0].passageID, "test");
      assert.equal(response.items[0].passageText, "Canônico");
    }
    assert.equal(calls, 2);
    fail = true;
    const res = { setHeader() {}, end() {} };
    await handler({ method: "POST", headers: {}, body: { passages: [{ id: "test", reference: "Salmo 1", text: "Canônico" }], itemCount: 1 } }, res);
    assert.equal(res.statusCode, 503);
    assert.equal(calls, 3);
    const deliveries = logs.filter(([event]) => event === "limiar_reading_delivery").map(([, data]) => data);
    assert.deepEqual(deliveries.map((entry) => entry.outcome), ["success", "success", "failure"]);
    assert.ok(!JSON.stringify(logs).includes("privado"));
    assert.ok(!JSON.stringify(logs).includes("Católica"));
  } finally {
    global.fetch = previousFetch;
    console.info = previousInfo;
    console.error = previousError;
    if (previousKey === undefined) delete process.env.OPENAI_API_KEY; else process.env.OPENAI_API_KEY = previousKey;
    if (previousSecret === undefined) delete process.env.LIMIAR_APP_SECRET; else process.env.LIMIAR_APP_SECRET = previousSecret;
  }
});

test("reading endpoint keeps final client order for one, two and three passages", async () => {
  const handler = require("../api/reading-session");
  const previousFetch = global.fetch;
  const previousKey = process.env.OPENAI_API_KEY;
  const previousInfo = console.info;
  const previousSecret = process.env.LIMIAR_APP_SECRET;
  process.env.OPENAI_API_KEY = "unit-test-key";
  delete process.env.LIMIAR_APP_SECRET;
  console.info = () => {};
  const fields = { homily: "Explicação", spiritualMeaning: "Sentido", practicalApplication: "Aplicação", conclusion: "Conclusão", meditationQuestion: "Pergunta?" };
  let count = 0;
  global.fetch = async () => ({
    ok: true,
    json: async () => ({ output_text: JSON.stringify({ items: Array.from({ length: count }, () => fields), reflection: fields }) })
  });
  try {
    const passages = [
      { id: "matthew", reference: "Mateus 6, 33", text: "Primeiro", book: "Mateus" },
      { id: "psalm", reference: "Salmo 23", text: "Segundo", book: "Salmos" },
      { id: "proverbs", reference: "Provérbios 3", text: "Terceiro", book: "Provérbios" }
    ];
    for (count of [1, 2, 3]) {
      let result;
      const res = { setHeader() {}, end(value) { result = JSON.parse(value); } };
      await handler({ method: "POST", headers: { "x-limiar-client-id": `final-order-${count}-${Date.now()}` }, body: {
        profile: { tradition: "Católica", favoriteBooks: ["Salmos"] },
        passages: passages.slice(0, count), itemCount: count
      } }, res);
      assert.deepEqual(result.items.map(item => item.passageID), passages.slice(0, count).map(item => item.id));
      assert.equal(result.reflection.reference, passages.slice(0, count).map(item => item.reference).join(" + "));
    }
    count = 3;
    let legacy;
    const res = { setHeader() {}, end(value) { legacy = JSON.parse(value); } };
    await handler({ method: "POST", headers: { "x-limiar-client-id": `legacy-order-${Date.now()}` }, body: {
      profile: { tradition: "Católica", favoriteBooks: ["Salmos"] }, passages
    } }, res);
    assert.equal(legacy.items[0].passageID, "psalm");
  } finally {
    global.fetch = previousFetch;
    console.info = previousInfo;
    if (previousKey === undefined) delete process.env.OPENAI_API_KEY; else process.env.OPENAI_API_KEY = previousKey;
    if (previousSecret === undefined) delete process.env.LIMIAR_APP_SECRET; else process.env.LIMIAR_APP_SECRET = previousSecret;
  }
});

const CATALOG = normalizePassages([
  { id: "psalm-23", reference: "Salmo 23", text: "O Senhor é meu pastor.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
  { id: "psalm-121", reference: "Salmo 121", text: "O Senhor te guarda.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
  { id: "proverbs-3", reference: "Provérbios 3, 5-6", text: "Confia no Senhor.", book: "Provérbios", section: "Sabedoria", theme: "Sabedoria" },
  { id: "proverbs-4", reference: "Provérbios 4, 23", text: "Guarda o teu coração.", book: "Provérbios", section: "Sabedoria", theme: "Sabedoria" },
  { id: "isaiah-40", reference: "Isaías 40, 31", text: "Renovam suas forças.", book: "Isaías", section: "Profetas", theme: "Esperança" },
  { id: "matthew-6", reference: "Mateus 6, 33", text: "Buscai primeiro o Reino.", book: "Mateus", section: "Evangelhos", theme: "Propósito" },
  { id: "john-14", reference: "João 14, 27", text: "Deixo-vos a paz.", book: "João", section: "Evangelhos", theme: "Ansiedade" },
  { id: "luke-10", reference: "Lucas 10, 41-42", text: "Uma só coisa é necessária.", book: "Lucas", section: "Evangelhos", theme: "Presença" }
]);

const PROFILE_WITH_BOOKS = normalizeProfile({
  tradition: "Católica",
  traditionID: "catholic",
  favoriteBooks: ["Salmos", "Provérbios", "Isaías"],
  favoriteSections: ["Salmos e Orações", "Sabedoria"],
  favoriteThemes: ["Esperança", "Sabedoria"],
  explanationDepth: "média"
});

test("reading handler keeps final selections, ordinal reflection and cards in one order", async (t) => {
  const handler = require("../api/reading-session");
  const savedEnvironment = Object.fromEntries(["OPENAI_API_KEY", "LIMIAR_APP_SECRET"].map(key => [key, process.env[key]]));
  process.env.OPENAI_API_KEY = "unit-test-key";
  delete process.env.LIMIAR_APP_SECRET;
  t.after(() => {
    for (const [key, value] of Object.entries(savedEnvironment)) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  });
  t.mock.method(console, "info", () => {});
  t.mock.method(console, "error", () => {});
  const fields = value => ({ homily: value, spiritualMeaning: value,
    practicalApplication: value, conclusion: value, meditationQuestion: `${value}?` });
  let prompt;
  let providerCalls = 0;
  t.mock.method(global, "fetch", async (_url, options) => {
    providerCalls += 1;
    prompt = JSON.parse(options.body).input;
    // The fake model follows the real numbered prompt, not the request array.
    // This makes a server reorder visible in both item homilies and reflection.
    const references = [...prompt.matchAll(/^Trecho \d+\nReferência: (.+)$/gm)].map(match => match[1]);
    const ordinalMeaning = references.map((ref, index) => `Trecho ${index + 1}: ${ref}`).join(" | ");
    return { ok: true, json: async () => ({ output_text: JSON.stringify({
      items: references.map(ref => fields(`Explicação de ${ref}`)),
      reflection: fields(ordinalMeaning)
    }) }) };
  });
  let requests = 0;
  async function request(body, expectedPassages) {
    const clientID = `order-regression-${++requests}`;
    let response;
    const res = { setHeader() {}, end(value) { response = JSON.parse(value); } };
    const expected = typeof expectedPassages === "function" ? expectedPassages(clientID) : expectedPassages;
    await handler({ method: "POST", headers: { "x-limiar-client-id": clientID }, body }, res);
    assert.equal(res.statusCode, 200);
    assert.equal(providerCalls, requests, "one provider call per request");
    assert.deepEqual(response.items.map(item => item.passageID), expected.map(p => p.id));
    assert.deepEqual(response.items.map(item => item.passageText), expected.map(p => p.text));
    assert.deepEqual(response.items.map(item => item.homily), expected.map(p => `Explicação de ${p.reference}`));
    assert.equal(response.reflection.reference, expected.map(p => p.reference).join(" + "));
    assert.equal(response.reflection.passageText, expected.map(p => `${p.reference}: ${p.text}`).join("\n\n"));
    assert.equal(response.reflection.spiritualMeaning, expected.map((p, i) => `Trecho ${i + 1}: ${p.reference}`).join(" | "));
  }
  function permutations(values) {
    if (values.length === 1) return [values];
    return values.flatMap((value, index) => permutations(values.filter((_, i) => i !== index)).map(rest => [value, ...rest]));
  }
  const finalPassages = [CATALOG[0], CATALOG[2], CATALOG[4]];
  for (const [tradition, traditionID] of [["Católica", "catholic"], ["Evangélica", "evangelical"], ["Judaica", "jewish"], ["Cristã ampla", "broadChristian"]]) {
    for (const itemCount of [1, 2, 3]) {
      for (const passages of permutations(finalPassages.slice(0, itemCount))) {
        for (const withHistory of [false, true]) {
          const profile = { tradition, traditionID, favoriteBooks: ["Salmos", "Provérbios", "Isaías"],
            priorityBooks: ["Isaías"], favoriteSections: ["Profetas"], favoriteThemes: ["Sabedoria"],
            avoidedBooks: ["João"], avoidedSections: ["Evangelhos"] };
          await request({ profile, passages, itemCount,
            recentPassageIDs: withHistory ? [passages[0].id, passages.at(-1).reference] : [],
            recentReflections: [{ reference: "Salmo anterior", summary: "Reflexão anterior" }],
            explanationDiversityVersion: withHistory ? 1 : undefined }, passages);
          assert.ok(prompt.includes(`Tradição: ${tradition} [${traditionID}]`));
          assert.ok(prompt.includes("Reflexão anterior"));
        }
      }
    }
  }
  // Explicit counts with pools and pre-itemCount clients keep server selection.
  for (const itemCount of [undefined, 1, 2, 3]) {
    for (const withHistory of [false, true]) {
      const profile = { ...PROFILE_WITH_BOOKS, priorityBooks: ["Isaías"], avoidedBooks: ["João"], avoidedSections: ["Evangelhos"] };
      const recentPassageIDs = withHistory ? CATALOG.slice(0, 3).map(p => p.id) : [];
      await request({ profile, passages: CATALOG, recentPassageIDs,
        ...(itemCount === undefined ? {} : { itemCount }) }, clientID => selectSessionPassages({
          profile: normalizeProfile(profile), passages: CATALOG, recentPassageIDs,
          count: itemCount ?? 3, seed: selectionSeed({ clientID })
        }).selected);
      assert.ok(!prompt.includes("Referência: João 14"));
      assert.ok(!prompt.includes("Referência: Mateus 6"));
    }
  }
  // A legacy exact-size pool has not opted into client ordering either.
  await request({ profile: PROFILE_WITH_BOOKS, passages: finalPassages }, clientID => selectSessionPassages({
    profile: PROFILE_WITH_BOOKS, passages: finalPassages, count: 3, seed: selectionSeed({ clientID })
  }).selected);
  for (const exclusions of [{ avoidedBooks: ["Salmos"] }, { avoidedSections: ["Salmos e Orações"] }]) {
    let response;
    const res = { setHeader() {}, end(value) { response = JSON.parse(value); } };
    const callsBefore = providerCalls;
    await handler({ method: "POST", headers: { "x-limiar-client-id": `order-excluded-${++requests}` },
      body: { profile: exclusions, passages: finalPassages, itemCount: 3 } }, res);
    assert.equal(providerCalls, callsBefore, "reject incomplete sessions before calling AI");
    assert.equal(res.statusCode, 400);
    assert.equal(response.error, "insufficient_eligible_passages");
  }
});

test("preserving a final selection order never restores excluded books or sections", () => {
  for (const exclusions of [{ avoidedBooks: ["Salmos"] }, { avoidedSections: ["Salmos e Orações"] }]) {
    const selection = selectSessionPassages({ profile: normalizeProfile(exclusions),
      passages: [CATALOG[0], CATALOG[2], CATALOG[4]], count: 3, preserveInputOrder: true });
    assert.equal(selection.selected.length, 2);
    assert.ok(selection.selected.every(p => p.id !== "psalm-23"));
  }
});

test("keeps GPT-5.4 mini as the default commercial text model", () => {
  assert.equal(DEFAULT_MODEL, "gpt-5.4-mini");
  assert.equal(DEFAULT_REASONING_EFFORT, "none");
});

test("tradition restrictions do not depend on client exclusion lists", () => {
  const references = ["Mateus 6", "Marcos 1", "Lucas 10", "João 14", "Atos 2", "Romanos 8",
    "1 Coríntios 13", "Gálatas 5", "Efésios 6", "Filipenses 4", "Colossenses 3",
    "2 Tessalonicenses 3", "I Timóteo 4", "Tito 2", "Filemom 1", "Hebreus 11",
    "Tiago 1", "2 Pedro 1", "III João 1", "Judas 1", "Apocalipse 21",
    "Tobias 4", "Judite 8", "Sabedoria 7", "Eclesiástico 2", "Baruque 3", "1 Macabeus 2"];
  for (const profile of [{ traditionID: "jewish" }, { tradition: "Judaica" }]) {
    for (const reference of references) {
      const passage = { id: reference, reference, text: "Texto" };
      for (const metadata of [{}, { book: "Salmos", section: "Salmos" }]) {
        assert.equal(selectSessionPassages({ profile: normalizeProfile(profile),
          passages: normalizePassages([{ ...passage, ...metadata }]), count: 1,
          preserveInputOrder: true }).selected.length, 0, reference);
      }
    }
  }
  for (const profile of [{ traditionID: "protestant" }, { tradition: "Evangélica" }]) {
    for (const reference of references.slice(-6)) {
      assert.equal(selectSessionPassages({ profile: normalizeProfile(profile),
        passages: normalizePassages([{ reference, text: "Texto" }]), count: 1 }).selected.length, 0);
    }
    assert.equal(selectSessionPassages({ profile: normalizeProfile(profile),
      passages: [CATALOG[6]], count: 1 }).selected.length, 1);
  }
  // Current catalog entries from each tradition remain eligible, including
  // bilingual Jewish references and all Catholic deuterocanonical passages.
  const catalog = require("../Limiar/Resources/passages.json");
  for (const passage of catalog) {
    const selection = selectSessionPassages({ profile: normalizeProfile({ traditionID: passage.tradition }),
      passages: normalizePassages([passage]), count: 1 });
    assert.equal(selection.selected.length, 1, passage.id);
  }
});

test("handler filters canon before AI and rejects incomplete sessions without provider calls", async (t) => {
  const handler = require("../api/reading-session");
  const saved = Object.fromEntries(["OPENAI_API_KEY", "LIMIAR_APP_SECRET"].map(key => [key, process.env[key]]));
  process.env.OPENAI_API_KEY = "unit-test-key";
  delete process.env.LIMIAR_APP_SECRET;
  t.after(() => {
    for (const [key, value] of Object.entries(saved)) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  });
  t.mock.method(console, "info", () => {});
  let calls = 0;
  let references;
  t.mock.method(global, "fetch", async (_, options) => {
    calls++;
    const prompt = JSON.parse(options.body).input;
    references = [...prompt.matchAll(/^Trecho \d+\nReferência: (.+)$/gm)].map(match => match[1]);
    const fields = { homily: "H", spiritualMeaning: "S", practicalApplication: "P", conclusion: "C", meditationQuestion: "Q" };
    return { ok: true, json: async () => ({ output_text: JSON.stringify({
      items: references.map(() => fields), reflection: fields }) }) };
  });
  let requestNumber = 0;
  async function request(body) {
    let response;
    const res = { setHeader() {}, end(value) { response = JSON.parse(value); } };
    await handler({ method: "POST", headers: { "x-limiar-client-id": `canon-count-${++requestNumber}` }, body }, res);
    return { status: res.statusCode, response };
  }
  const allowed = [CATALOG[0], CATALOG[2], CATALOG[4]];
  const forbidden = [CATALOG[6], { id: "tobias", reference: "Tobias 4", text: "Texto", book: "Tobias" }];
  for (const profile of [{ traditionID: "jewish" }, { tradition: "Judaica" },
    { traditionID: "protestant" }, { tradition: "Evangélica" }]) {
    const badPassage = profile.traditionID === "jewish" || profile.tradition === "Judaica" ? forbidden[0] : forbidden[1];
    for (const itemCount of [undefined, 1, 2, 3]) {
      const count = itemCount ?? 3;
      const countBody = itemCount === undefined ? {} : { itemCount };
      const before = calls;
      const invalid = await request({ profile, ...countBody, passages: [badPassage, ...allowed.slice(0, count - 1)] });
      assert.equal(invalid.status, 400);
      assert.equal(invalid.response.error, "insufficient_eligible_passages");
      assert.equal(calls, before);
      const valid = await request({ profile, ...countBody, passages: [badPassage, ...allowed] });
      assert.equal(valid.status, 200);
      assert.equal(calls, before + 1);
      assert.equal(valid.response.items.length, count);
      assert.deepEqual(valid.response.items.map(item => item.reference), references);
      assert.ok(!references.includes(badPassage.reference));
    }
  }
  const excludedAll = await request({ itemCount: 2, profile: { avoidedBooks: ["Salmos"] }, passages: CATALOG.slice(0, 2) });
  assert.equal(excludedAll.status, 400);
  assert.equal(excludedAll.response.error, "insufficient_eligible_passages");
});

test("keeps ElevenLabs Flash as the economical default voice model", () => {
  assert.equal(DEFAULT_TTS_MODEL, "eleven_flash_v2_5");
  assert.equal(DEFAULT_TTS_VOICE_ID, "21m00Tcm4TlvDq8ikWAM");
  assert.equal(DEFAULT_TTS_SPEED, 0.92);
});

test("uses Azure and Antonio Neural as the default speech path", () => {
  assert.equal(normalizeTTSProvider(""), "azure");
  assert.equal(normalizeTTSProvider("elevenlabs"), "elevenlabs");
  assert.equal(DEFAULT_AZURE_SPEECH_RATE, "-10%");
  assert.equal(DEFAULT_AZURE_SPEECH_PITCH, "-3%");
  assert.equal(DEFAULT_AZURE_SPEECH_BREAK_MS, 500);
  assert.equal(AZURE_REFERENCE_SPEECH_VERSION, "v1");
  assert.equal(DEFAULT_AZURE_SPEECH_VOICE, "pt-BR-AntonioNeural");
});

test("fixes the canonical passage narration format used by the prewarmed cache", () => {
  assert.equal(
    canonicalPassageNarrationText("Salmo 23", "O Senhor é meu pastor."),
    "Salmo 23.\nO Senhor é meu pastor."
  );
});

test("proclaims every reference format used by the catalog and preserves unknown formats", () => {
  assert.equal(spokenReference("Salmo 23"), "Salmo 23");
  assert.equal(spokenReference("Salmo 118, 24"), "Salmo 118, versículo 24");
  assert.equal(spokenReference("Mateus 11, 28-30"), "Mateus 11, versículos 28 a 30");
  assert.equal(spokenReference("Provérbios 3, 5-6"), "Provérbios 3, versículos 5 a 6");
  assert.equal(spokenReference("Salmo 46:10"), "Salmo 46, versículo 10");
  assert.equal(
    spokenReference("Tehillim / Salmo 46:10"),
    "Tehillim, Salmo 46, versículo 10"
  );
  assert.equal(spokenReference("Referência livre sem padrão"), "Referência livre sem padrão");
});

test("narrates every new catalog reference without attribution and with the verse pause", () => {
  const catalog = require("../Limiar/Resources/passages.json");
  for (const passage of catalog.filter(p => p.id.startsWith("blivre-2018-"))) {
    const text = canonicalPassageNarrationText(passage.reference, passage.text);
    const ssml = buildAzureSpeechSSML(text, "pt-BR-AntonioNeural", { breakMs: 500 });
    assert.doesNotMatch(ssml, /BLIVRE/);
    assert.match(ssml, /versículo/);
    assert.match(ssml, /<break time='500ms'\/>/);
    assert.match(azureSpeechCadence(text), /\|blivre-reference:v1$/);
    assert.ok(text.includes("BLIVRE"), "canonical input and visible attribution stay intact");
  }
  assert.equal(spokenReference("Referência livre · BLIVRE"), "Referência livre · BLIVRE");
  assert.equal(spokenReference("Salmo 23 · BLIVRE"), "Salmo 23");
  assert.match(azureSpeechCadence("Salmo 23 · BLIVRE.\nTexto"), /chapter-break-fix:v1\|blivre-reference:v1$/);
});

test("keeps canonical inputs, speech and cadence identical for all 977 legacy passages", () => {
  const catalog = require("../Limiar/Resources/passages.json");
  const tone = azureSpeechTone({ rate: "-10%", pitch: "-3%", breakMs: 500, referenceSpeechVersion: "v1" });
  const rows = catalog.filter(p => !p.id.startsWith("blivre-2018-")).map(p => {
    const text = canonicalPassageNarrationText(p.reference, p.text);
    return [text, buildAzureSpeechSSML(text, "pt-BR-AntonioNeural", tone), azureSpeechCadence(text, tone)];
  });
  assert.equal(rows.length, 977);
  const digest = require("node:crypto").createHash("sha256").update(JSON.stringify(rows)).digest("hex");
  assert.equal(digest, "581be128c91641bfda9c01495dda1fbbe21c11b0549bdfff500bfd6540f7b9b6");
});

test("selects only preferred books when there are enough fresh passages", () => {
  const selection = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG,
    recentPassageIDs: [],
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  assert.equal(selection.selected.length, 3);
  for (const passage of selection.selected) {
    assert.equal(["Salmos", "Provérbios", "Isaías"].includes(passage.book), true);
  }
  assert.equal(selection.selectionTier, "favorite-books");
  assert.equal(selection.reusedRecentCount, 0);
});

test("avoids recent passages while fresh preferred passages remain", () => {
  const selection = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG,
    recentPassageIDs: ["psalm-23", "Salmo 23", "proverbs-3"],
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  const ids = selection.selected.map((passage) => passage.id);
  assert.equal(ids.includes("psalm-23"), false);
  assert.equal(ids.includes("proverbs-3"), false);
  for (const passage of selection.selected) {
    assert.equal(["Salmos", "Provérbios", "Isaías"].includes(passage.book), true);
  }
});

test("rotates least recently used passages when the preferred pool is exhausted", () => {
  // Todos os trechos de livros preferidos já são recentes: psalm-23 é o MAIS
  // antigo do histórico (última posição) e deve voltar antes dos demais.
  const selection = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG.filter((passage) => ["Salmos", "Provérbios", "Isaías"].includes(passage.book)),
    recentPassageIDs: ["isaiah-40", "proverbs-4", "proverbs-3", "psalm-121", "psalm-23"],
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  assert.equal(selection.selected.length, 3);
  assert.equal(selection.reusedRecentCount > 0, true);
  const ids = selection.selected.map((passage) => passage.id);
  assert.equal(ids.includes("psalm-23"), true);
  assert.equal(ids.includes("isaiah-40"), false);
});

test("stays inside preferred books via LRU rotation instead of widening", () => {
  // Todos os trechos dos livros preferidos são recentes, mas o pool preferido
  // tem >= 3 trechos: deve rotacionar dentro deles, nunca trazer Mateus/João.
  const preferredIDs = CATALOG
    .filter((passage) => ["Salmos", "Provérbios", "Isaías"].includes(passage.book))
    .map((passage) => passage.id);
  const selection = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG,
    recentPassageIDs: preferredIDs,
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  assert.equal(selection.selected.length, 3);
  for (const passage of selection.selected) {
    assert.equal(["Salmos", "Provérbios", "Isaías"].includes(passage.book), true);
  }
  assert.equal(selection.reusedRecentCount, 3);
});

test("widens beyond preferred books only when needed", () => {
  const onlyOnePreferred = CATALOG.filter(
    (passage) => passage.book !== "Salmos" && passage.book !== "Provérbios"
  );
  const selection = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: onlyOnePreferred,
    recentPassageIDs: [],
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  assert.equal(selection.selected.length, 3);
  const ids = selection.selected.map((passage) => passage.id);
  assert.equal(ids.includes("isaiah-40"), true);
  assert.equal(selection.selectionTier !== "favorite-books", true);
});

test("never selects passages from avoided books", () => {
  const jewishProfile = normalizeProfile({
    tradition: "Judaica",
    traditionID: "jewish",
    favoriteBooks: [],
    avoidedBooks: ["Mateus", "Lucas", "João"],
    explanationDepth: "curta"
  });
  const selection = selectSessionPassages({
    profile: jewishProfile,
    passages: CATALOG,
    recentPassageIDs: [],
    count: SESSION_ITEM_COUNT,
    seed: "unit-seed"
  });

  for (const passage of selection.selected) {
    assert.equal(["Mateus", "Lucas", "João"].includes(passage.book), false);
  }
});

test("selection is deterministic for the same seed", () => {
  const first = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG,
    recentPassageIDs: ["psalm-23"],
    count: SESSION_ITEM_COUNT,
    seed: "same-seed"
  });
  const second = selectSessionPassages({
    profile: PROFILE_WITH_BOOKS,
    passages: CATALOG,
    recentPassageIDs: ["psalm-23"],
    count: SESSION_ITEM_COUNT,
    seed: "same-seed"
  });

  assert.deepEqual(
    first.selected.map((passage) => passage.id),
    second.selected.map((passage) => passage.id)
  );
});

test("uses two priority-book passages and keeps a discovery passage", () => {
  const selection = selectSessionPassages({
    profile: normalizeProfile({ favoriteBooks: ["Salmos", "Provérbios", "Mateus"], priorityBooks: ["Salmos"], explanationDepth: "média" }),
    passages: CATALOG,
    recentPassageIDs: [],
    count: 3,
    seed: "priority-quota"
  });
  assert.equal(selection.priorityCount, 2);
  assert.equal(selection.selected.filter((passage) => passage.book === "Salmos").length, 2);
  assert.equal(selection.selected.some((passage) => passage.book !== "Salmos"), true);
});

test("adapts priority and discovery quotas for one, two and three items", () => {
  const profile = normalizeProfile({
    favoriteBooks: ["Salmos", "Provérbios", "Mateus"],
    priorityBooks: ["Salmos"],
    favoriteThemes: ["Propósito"],
    explanationDepth: "média"
  });

  const one = selectSessionPassages({
    profile,
    passages: CATALOG,
    recentPassageIDs: [],
    count: 1,
    seed: "adaptive-one"
  });
  assert.equal(one.selected.length, 1);
  assert.equal(one.priorityCount, 1);
  assert.equal(one.selected[0].book, "Salmos");

  const two = selectSessionPassages({
    profile,
    passages: CATALOG,
    recentPassageIDs: [],
    count: 2,
    seed: "adaptive-two"
  });
  assert.equal(two.selected.length, 2);
  assert.equal(two.priorityCount, 1);
  assert.equal(two.selected.some((passage) => passage.book !== "Salmos"), true);
  assert.equal(two.selected.some((passage) => passage.theme === "Propósito"), true);

  const three = selectSessionPassages({
    profile,
    passages: CATALOG,
    recentPassageIDs: [],
    count: 3,
    seed: "adaptive-three"
  });
  assert.equal(three.selected.length, 3);
  assert.equal(three.priorityCount, 2);
  assert.equal(three.selected.some((passage) => passage.book !== "Salmos"), true);
});

test("keeps a single refined-book passage instead of ejecting it for theme guarantee", () => {
  const selection = selectSessionPassages({
    profile: normalizeProfile({
      favoriteBooks: ["Salmos", "Mateus"],
      priorityBooks: ["Salmos"],
      favoriteThemes: ["Propósito"],
      explanationDepth: "média"
    }),
    passages: CATALOG,
    recentPassageIDs: [],
    count: 1,
    seed: "single-refined-wins"
  });

  assert.equal(selection.selected.length, 1);
  assert.equal(selection.selected[0].book, "Salmos");
  assert.equal(selection.priorityCount, 1);
  assert.equal(selection.favoriteThemeCount, 0);
});

test("resolves adaptive item counts while preserving the legacy payload", () => {
  const legacy = resolveReadingSessionOptions({}, "curta", 8);
  assert.deepEqual(legacy, {
    hasItemCount: false,
    requestedItemCount: 3,
    itemCount: 3,
    generationDepth: "curta",
    outputBudgetDepth: "curta"
  });

  const one = resolveReadingSessionOptions({ itemCount: 0 }, "grande", 8);
  assert.equal(one.itemCount, 1);
  assert.equal(one.generationDepth, "curta");
  assert.equal(one.outputBudgetDepth, "curta");
  assert.equal(depthOutputTokenLimit(one.outputBudgetDepth, "reading-session"), 2800);

  const two = resolveReadingSessionOptions({ itemCount: 2 }, "curta", 8);
  assert.equal(two.itemCount, 2);
  assert.equal(two.generationDepth, "média");
  assert.equal(two.outputBudgetDepth, "média");

  const three = resolveReadingSessionOptions({ itemCount: 9 }, "grande", 8);
  assert.equal(three.itemCount, 3);
  assert.equal(three.generationDepth, "média");
  assert.equal(three.outputBudgetDepth, "média");
});

test("adaptive selection remains deterministic for every supported item count", () => {
  for (const count of [1, 2, 3]) {
    const profile = normalizeProfile({
      favoriteBooks: ["Salmos", "Provérbios", "Mateus"],
      priorityBooks: ["Salmos"],
      favoriteThemes: ["Propósito"]
    });
    const first = selectSessionPassages({ profile, passages: CATALOG, count, seed: `count-${count}` });
    const second = selectSessionPassages({ profile, passages: CATALOG, count, seed: `count-${count}` });
    assert.deepEqual(
      first.selected.map((passage) => passage.id),
      second.selected.map((passage) => passage.id)
    );
  }
});

test("degrades priority quota without repeating recent passages", () => {
  const selection = selectSessionPassages({
    profile: normalizeProfile({ favoriteBooks: ["Salmos", "Provérbios", "Mateus"], priorityBooks: ["Salmos"], explanationDepth: "média" }),
    passages: CATALOG,
    recentPassageIDs: ["psalm-23", "psalm-121"],
    count: 3,
    seed: "priority-degrade"
  });
  assert.equal(selection.priorityCount, 0);
  assert.equal(selection.reusedRecentCount, 0);
  assert.equal(selection.selected.some((passage) => passage.id === "psalm-23" || passage.id === "psalm-121"), false);
});

test("keeps priority selection deterministic", () => {
  const profile = normalizeProfile({ favoriteBooks: ["Salmos", "Provérbios", "Mateus"], priorityBooks: ["Salmos"], favoriteThemes: ["Propósito"], explanationDepth: "média" });
  const first = selectSessionPassages({ profile, passages: CATALOG, recentPassageIDs: [], count: 3, seed: "priority-stable" });
  const second = selectSessionPassages({ profile, passages: CATALOG, recentPassageIDs: [], count: 3, seed: "priority-stable" });
  assert.deepEqual(first.selected.map((passage) => passage.id), second.selected.map((passage) => passage.id));
});

test("guarantees a favorite theme without replacing a priority passage", () => {
  const selection = selectSessionPassages({
    profile: normalizeProfile({ favoriteBooks: ["Salmos", "Provérbios", "Mateus"], priorityBooks: ["Salmos"], favoriteThemes: ["Propósito"], explanationDepth: "média" }),
    passages: CATALOG,
    recentPassageIDs: [],
    count: 3,
    seed: "theme-guarantee"
  });
  assert.equal(selection.favoriteThemeCount >= 1, true);
  assert.equal(selection.selected.some((passage) => passage.theme === "Propósito"), true);
  assert.equal(selection.selected.filter((passage) => passage.book === "Salmos").length, 2);
});

test("does not force a favorite theme when no fresh candidate exists", () => {
  const selection = selectSessionPassages({
    profile: normalizeProfile({ favoriteBooks: ["Salmos", "Provérbios"], favoriteThemes: ["Propósito"], explanationDepth: "média" }),
    passages: CATALOG.filter((passage) => passage.theme !== "Propósito"),
    recentPassageIDs: [],
    count: 3,
    seed: "theme-absent"
  });
  assert.equal(selection.favoriteThemeCount, 0);
  assert.equal(selection.reusedRecentCount, 0);
});

test("legacy profiles without priorityBooks keep the strong book filter even with themes", () => {
  // Builds antigos enviam favoriteThemes mas não priorityBooks: a garantia de
  // tema NÃO pode ejetar um livro escolhido para injetar Mateus (Propósito).
  const selection = selectSessionPassages({
    profile: normalizeProfile({
      favoriteBooks: ["Salmos", "Provérbios", "Isaías"],
      favoriteThemes: ["Propósito"],
      explanationDepth: "média"
    }),
    passages: CATALOG,
    recentPassageIDs: [],
    count: 3,
    seed: "legacy-theme"
  });
  for (const passage of selection.selected) {
    assert.equal(["Salmos", "Provérbios", "Isaías"].includes(passage.book), true);
  }
  assert.equal(selection.favoriteThemeCount, 0);
});

test("theme guarantee never leaves the chosen books", () => {
  // Presença só existe em Lucas, que não está nos livros escolhidos: a troca
  // de tema não pode trazer um livro de fora da união.
  const selection = selectSessionPassages({
    profile: normalizeProfile({
      favoriteBooks: ["Salmos", "Provérbios"],
      priorityBooks: ["Salmos"],
      favoriteThemes: ["Presença"],
      explanationDepth: "média"
    }),
    passages: CATALOG,
    recentPassageIDs: [],
    count: 3,
    seed: "theme-outside"
  });
  for (const passage of selection.selected) {
    assert.equal(["Salmos", "Provérbios"].includes(passage.book), true);
  }
  assert.equal(selection.favoriteThemeCount, 0);
});

test("priority books rotate via LRU instead of widening when fresh ones run out", () => {
  // favoritos == prioritários com 2 frescos e 2 recentes: a cota pega os 2
  // frescos e a 3ª vaga rotaciona o Salmo mais antigo — nunca amplia para um
  // livro que o usuário não escolheu.
  const psalmCatalog = normalizePassages([
    { id: "psalm-23", reference: "Salmo 23", text: "O Senhor é meu pastor.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
    { id: "psalm-121", reference: "Salmo 121", text: "O Senhor te guarda.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
    { id: "psalm-27", reference: "Salmo 27", text: "O Senhor é minha luz.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
    { id: "psalm-91", reference: "Salmo 91", text: "Sob as asas do Altíssimo.", book: "Salmos", section: "Salmos e Orações", theme: "Esperança" },
    { id: "matthew-6", reference: "Mateus 6, 33", text: "Buscai primeiro o Reino.", book: "Mateus", section: "Evangelhos", theme: "Propósito" },
    { id: "luke-10", reference: "Lucas 10, 41-42", text: "Uma só coisa é necessária.", book: "Lucas", section: "Evangelhos", theme: "Presença" }
  ]);
  const selection = selectSessionPassages({
    profile: normalizeProfile({ favoriteBooks: ["Salmos"], priorityBooks: ["Salmos"], explanationDepth: "média" }),
    passages: psalmCatalog,
    recentPassageIDs: ["psalm-27", "psalm-91"],
    count: 3,
    seed: "priority-lru"
  });
  assert.equal(selection.selected.length, 3);
  for (const passage of selection.selected) {
    assert.equal(passage.book, "Salmos");
  }
  assert.equal(selection.selectionTier, "favorite-books");
  assert.equal(selection.reusedRecentCount, 1);
  assert.equal(selection.selected.some((passage) => passage.id === "psalm-91"), true);
});

test("speech cache key accepts only allowlisted Azure voices and ignores client speed", () => {
  const speech = require("../api/speech");
  const forged = speech.cacheKey({ text: "Bom dia", voice: "qualquer 0.92 coisa", speed: "9" });
  const legit = speech.cacheKey({ text: "Bom dia" });
  assert.equal(forged, legit);
  const francisca = speech.cacheKey({ text: "Bom dia", voice: "pt-BR-FranciscaNeural", speed: "1.4" });
  assert.notEqual(francisca, legit);
  assert.equal(
    francisca,
    speech.cacheKey({ text: "Bom dia", voice: "pt-BR-FranciscaNeural", speed: "0.8" })
  );
  assert.equal(azureSpeechVoice("pt-BR-BrendaNeural"), "pt-BR-BrendaNeural");
  assert.equal(azureSpeechVoice("voz-forjada"), DEFAULT_AZURE_SPEECH_VOICE);
  const otherText = speech.cacheKey({ text: "Boa noite" });
  assert.notEqual(legit, otherText);
});

test("speech cache key changes when any effective Azure tone parameter changes", () => {
  const speech = require("../api/speech");
  const names = ["AZURE_SPEECH_RATE", "AZURE_SPEECH_PITCH", "AZURE_SPEECH_BREAK_MS"];
  const previous = Object.fromEntries(names.map((name) => [name, process.env[name]]));
  const restore = () => {
    for (const name of names) {
      if (previous[name] === undefined) delete process.env[name];
      else process.env[name] = previous[name];
    }
  };

  try {
    for (const name of names) delete process.env[name];
    const defaultKey = speech.cacheKey({ text: "Salmo 23.\nO Senhor é meu pastor." });
    const cases = [
      ["AZURE_SPEECH_RATE", "-12%"],
      ["AZURE_SPEECH_PITCH", "-5%"],
      ["AZURE_SPEECH_BREAK_MS", "700"]
    ];
    for (const [name, value] of cases) {
      for (const resetName of names) delete process.env[resetName];
      process.env[name] = value;
      assert.notEqual(speech.cacheKey({ text: "Salmo 23.\nO Senhor é meu pastor." }), defaultKey);
    }
  } finally {
    restore();
  }
});

test("invalidates only chapter-only narration after the proclaimed pause fix", () => {
  const speech = require("../api/speech");
  const chapterText = canonicalPassageNarrationText("Salmo 23", "O Senhor é meu pastor.");
  const slashChapterText = canonicalPassageNarrationText(
    "Tehillim / Salmo 121",
    "Elevo os meus olhos para os montes."
  );
  const verseText = canonicalPassageNarrationText("Salmo 118, 24", "Este é o dia do Senhor.");
  const chapterConfig = speech.speechConfig({ text: chapterText });
  const slashChapterConfig = speech.speechConfig({ text: slashChapterText });
  const verseConfig = speech.speechConfig({ text: verseText });

  assert.match(chapterConfig.cadence, /\|chapter-break-fix:v1$/);
  assert.match(slashChapterConfig.cadence, /\|chapter-break-fix:v1$/);
  assert.equal(verseConfig.cadence, azureSpeechCadence(verseText));
  assert.doesNotMatch(verseConfig.cadence, /chapter-break-fix/);

  const legacyChapterConfig = {
    ...chapterConfig,
    cadence: chapterConfig.cadence.replace("|chapter-break-fix:v1", "")
  };
  assert.notEqual(
    speech.cacheKey({ text: chapterText }, chapterConfig),
    speech.cacheKey({ text: chapterText }, legacyChapterConfig)
  );
});

test("speech cache key normalizes forged voice/speed on the ElevenLabs path", () => {
  const speech = require("../api/speech");
  const previous = process.env.TTS_PROVIDER;
  process.env.TTS_PROVIDER = "elevenlabs";
  try {
    // Voz com espaços e velocidade não numérica não podem deslocar os campos
    // da chave para colidir com a chave legítima de outro texto.
    const forged = speech.cacheKey({ voice: "abc 0.92 Bom", speed: "x", text: "dia" });
    const legit = speech.cacheKey({ voice: "abc", speed: 0.92, text: "Bom dia" });
    assert.notEqual(forged, legit);
    const config = speech.speechConfig({ voice: "a b\tc", speed: "5" });
    assert.equal(config.voice.includes(" "), false);
    assert.equal(Number(config.speed) <= 1.1, true);
  } finally {
    if (previous === undefined) delete process.env.TTS_PROVIDER;
    else process.env.TTS_PROVIDER = previous;
  }
});

test("keeps up to forty normalized books", () => {
  const books = Array.from({ length: 45 }, (_, index) => `Livro ${index}`);
  const profile = normalizeProfile({ favoriteBooks: books, favoriteBookIDs: books, priorityBooks: books, avoidedBooks: books });
  assert.equal(profile.favoriteBooks.length, 40);
  assert.equal(profile.favoriteBookIDs.length, 40);
  assert.equal(profile.priorityBooks.length, 40);
  assert.equal(profile.avoidedBooks.length, 40);
});

test("builds an explanation prompt that fixes the passages and order", () => {
  const prompt = buildExplanationPrompt({
    profile: PROFILE_WITH_BOOKS,
    selectedPassages: CATALOG.slice(0, 3),
    recentReflections: normalizeRecentReflections([
      { reference: "Salmo 23", summary: "Resumo anterior", meditationQuestion: "Pergunta anterior?" }
    ]),
    includeReflection: true
  });

  assert.match(prompt, /exatamente 3 trechos/);
  assert.match(prompt, /items\[0\] corresponde ao Trecho 1/);
  assert.match(prompt, /Trecho 1\nReferência: Salmo 23/);
  assert.match(prompt, /Regras para reflection/);
  assert.match(prompt, /items\[0\]\.homily e reflection\.homily devem ter exatamente 2 parágrafos/);
  assert.match(prompt, /reflection\.practicalApplication deve ter exatamente 3 frases em um único parágrafo/);
  assert.match(prompt, /Resumo anterior/);
  assert.doesNotMatch(prompt, /Selecione|escolha os 3/i);
});

test("validates explanation items and rejects incomplete ones", () => {
  const explanation = {
    homily: "Uma leitura breve e acolhedora.",
    spiritualMeaning: "O trecho recorda cuidado e direção.",
    practicalApplication: "Respire antes de abrir o app.",
    conclusion: "Atravesse com presença.",
    meditationQuestion: "Que escolha ajuda você agora?"
  };

  const items = validateExplanationItems({ items: [explanation, explanation, explanation] }, 3);
  assert.equal(items.length, 3);

  assert.throws(() => validateExplanationItems({ items: [explanation, explanation] }, 3), /fewer items/);
  assert.throws(
    () => validateExplanationFields({ ...explanation, homily: "" }),
    (error) => error?.code === "missing_homily"
  );
});

test("assembles response items from the selected passages, not from the AI", () => {
  const explanation = {
    homily: "Explicação.",
    spiritualMeaning: "Sentido.",
    practicalApplication: "Aplicação.",
    conclusion: "Conclusão.",
    meditationQuestion: "Pergunta?"
  };
  const selected = CATALOG.slice(0, 2);
  const items = assembleReadingItems(selected, [explanation, explanation]);

  assert.equal(items[0].reference, "Salmo 23");
  assert.equal(items[0].passageText, "O Senhor é meu pastor.");
  assert.equal(items[0].passageID, "psalm-23");
  assert.equal(items[0].book, "Salmos");
  assert.equal(items[1].reference, "Salmo 121");

  const reflection = assembleReflection(selected, explanation);
  assert.equal(reflection.reference, "Salmo 23 + Salmo 121");
  assert.match(reflection.passageText, /Salmo 121: O Senhor te guarda\./);
});

test("keeps a strict schema compatible with structured outputs", () => {
  const schema = readingSessionExplanationSchema(3);
  assert.equal(schema.properties.items.minItems, undefined);
  assert.equal(schema.properties.items.maxItems, undefined);
  assert.equal(schema.additionalProperties, false);
  assert.equal(schema.properties.items.items.additionalProperties, false);
  assert.deepEqual(schema.required, ["items", "reflection"]);
});

test("parses provider JSON even when wrapped in markdown text", () => {
  const parsed = parseProviderJSON('```json\n{"homily":"Leitura acolhedora."}\n```');
  assert.equal(parsed.homily, "Leitura acolhedora.");
});

test("can enforce a simple per-client AI rate limit", () => {
  const previousMax = process.env.LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS;
  const previousWindow = process.env.LIMIAR_AI_RATE_LIMIT_WINDOW_MS;
  process.env.LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS = "1";
  process.env.LIMIAR_AI_RATE_LIMIT_WINDOW_MS = "60000";

  const req = {
    headers: {
      "x-limiar-client-id": `unit-${Date.now()}-${Math.random()}`
    }
  };
  const res = {
    statusCode: 200,
    headers: {},
    body: "",
    setHeader(key, value) {
      this.headers[key] = value;
    },
    end(value) {
      this.body = value;
    }
  };

  assert.equal(enforceAIRateLimit(req, res, "reflection").allowed, true);
  assert.equal(enforceAIRateLimit(req, res, "reflection").allowed, false);
  assert.equal(res.statusCode, 429);
  assert.match(res.body, /ai_rate_limited/);

  if (previousMax === undefined) {
    delete process.env.LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS;
  } else {
    process.env.LIMIAR_AI_RATE_LIMIT_MAX_REQUESTS = previousMax;
  }
  if (previousWindow === undefined) {
    delete process.env.LIMIAR_AI_RATE_LIMIT_WINDOW_MS;
  } else {
    process.env.LIMIAR_AI_RATE_LIMIT_WINDOW_MS = previousWindow;
  }
});

test("rejects requests without the app secret when it is configured", () => {
  const previousSecret = process.env.LIMIAR_APP_SECRET;
  process.env.LIMIAR_APP_SECRET = "unit-secret";

  const makeRes = () => ({
    statusCode: 200,
    headers: {},
    body: "",
    setHeader(key, value) {
      this.headers[key] = value;
    },
    end(value) {
      this.body = value;
    }
  });

  const withoutKey = {
    headers: { "x-limiar-client-id": `unit-secret-${Math.random()}` }
  };
  const resWithout = makeRes();
  assert.equal(enforceAIRateLimit(withoutKey, resWithout, "reading-session").allowed, false);
  assert.equal(resWithout.statusCode, 401);
  assert.match(resWithout.body, /unauthorized/);

  const withKey = {
    headers: {
      "x-limiar-client-id": `unit-secret-${Math.random()}`,
      "x-limiar-app-key": "unit-secret"
    }
  };
  assert.equal(enforceAIRateLimit(withKey, makeRes(), "reading-session").allowed, true);

  if (previousSecret === undefined) {
    delete process.env.LIMIAR_APP_SECRET;
  } else {
    process.env.LIMIAR_APP_SECRET = previousSecret;
  }

  const noSecretConfigured = {
    headers: { "x-limiar-client-id": `unit-secret-${Math.random()}` }
  };
  delete process.env.LIMIAR_APP_SECRET;
  assert.equal(enforceAIRateLimit(noSecretConfigured, makeRes(), "reading-session").allowed, true);
  if (previousSecret !== undefined) {
    process.env.LIMIAR_APP_SECRET = previousSecret;
  }
});

test("prepares speech text without technical markup", () => {
  const text = normalizeSpeechInput("### Título\n- Item com `json_key` e {marcação}\n\nTexto final.");
  assert.doesNotMatch(text, /###|`|json_key|\{|\}/);
  assert.match(text, /Texto final/);
});

test("builds Azure SSML with escaped, normalized Portuguese speech text", () => {
  const names = ["AZURE_SPEECH_RATE", "AZURE_SPEECH_PITCH", "AZURE_SPEECH_BREAK_MS"];
  const previous = Object.fromEntries(names.map((name) => [name, process.env[name]]));

  try {
    for (const name of names) delete process.env[name];
    const ssml = buildAzureSpeechSSML(
      'Salmo 118, 24.\n### Olá & "paz" <sempre>',
      "pt-BR-AntonioNeural"
    );
    assert.match(ssml, /voice name='pt-BR-AntonioNeural'/);
    assert.match(ssml, /rate='-10%'/);
    assert.match(ssml, /pitch='-3%'/);
    assert.match(ssml, /Salmo 118, versículo 24\.<break time='500ms'\/>/);
    assert.match(ssml, /Olá &amp; &quot;paz&quot; &lt;sempre&gt;/);
    assert.doesNotMatch(ssml, /###/);
  } finally {
    for (const name of names) {
      if (previous[name] === undefined) delete process.env[name];
      else process.env[name] = previous[name];
    }
  }
});

test("adds the devotional pause after chapter-only references and preserves separation at zero", () => {
  const withPause = buildAzureSpeechSSML(
    "Salmo 23.\nO Senhor é meu pastor.",
    "pt-BR-AntonioNeural"
  );
  assert.match(withPause, /Salmo 23\.<break time='500ms'\/>O Senhor/);

  const withoutBreak = buildAzureSpeechSSML(
    "Salmo 23.\nO Senhor é meu pastor.",
    "pt-BR-AntonioNeural",
    { breakMs: 0 }
  );
  assert.match(withoutBreak, /Salmo 23\. O Senhor/);
  assert.doesNotMatch(withoutBreak, /Salmo 23\.O Senhor/);
});

test("normalizes depth synonyms and changes guidance clearly", () => {
  assert.equal(normalizeProfile({ explanationDepth: "curta" }).explanationDepth, "curta");
  assert.equal(normalizeProfile({ explanationDepth: "média" }).explanationDepth, "média");
  assert.equal(normalizeProfile({ explanationDepth: "Mais profunda" }).explanationDepth, "grande");
  assert.match(depthGuidance("curta"), /exatamente 2 parágrafos desenvolvidos/);
  assert.match(depthGuidance("curta"), /Nunca entregue um único parágrafo/);
  assert.match(depthGuidance("curta"), /quem fala, para quem e em que situação/);
  assert.match(depthGuidance("curta"), /exatamente 2 ou 3 frases/);
  assert.match(depthGuidance("curta"), /não podem repetir ideias nem frases da homily/);
  assert.match(depthGuidance("média"), /1 a 2 parágrafos/);
  assert.match(depthGuidance("grande"), /2 a 3 parágrafos/);
});

test("adapts reflection guidance to morning, afternoon and evening without changing passages", () => {
  assert.match(pauseTurnGuidance("morning"), /direção para o dia que começa/);
  assert.match(pauseTurnGuidance("afternoon"), /recentralização no meio do dia/);
  assert.match(pauseTurnGuidance("evening"), /exame sereno do dia/);

  const prompt = buildExplanationPrompt({
    profile: normalizeProfile({
      tradition: "Católica",
      explanationDepth: "média",
      pauseTurn: "evening"
    }),
    selectedPassages: [CATALOG[0]],
    recentReflections: [],
    includeReflection: true
  });
  assert.match(prompt, /preparação para descanso/);
  assert.match(prompt, /Para lembrar hoje/);
  assert.match(prompt, /Nenhum bloco pode resumir, parafrasear ou repetir/);
});

test("uses output budgets sized for one rich short passage", () => {
  assert.equal(depthOutputTokenLimit("curta", "reading-session"), 2800);
  assert.equal(depthOutputTokenLimit("curta", "spiritual-reading"), 2400);
  assert.equal(depthOutputTokenLimit("curta", "reflection"), 1400);
  assert.equal(depthOutputTokenLimit("média", "reflection") < depthOutputTokenLimit("grande", "reflection"), true);
  assert.equal(
    depthOutputTokenLimit("grande", "reading-session") > depthOutputTokenLimit("grande", "reflection"),
    true
  );
});

test("keeps Ana's canonical testimonial identical in the app and site", () => {
  const quote = "Simplesmente perfeito! Eu sempre abria o Instagram ou TikTok sem pensar e perdia horas. Com o Limiar, antes de qualquer distração aparece uma leitura rápida e uma reflexão. Mudou completamente minha rotina. Consigo começar o dia mais centrado e ainda consigo ler a Bíblia sem forçar.";
  const repositoryRoot = path.resolve(__dirname, "..");
  const appCatalog = fs.readFileSync(path.join(repositoryRoot, "Limiar", "SharedUI.swift"), "utf8");
  const site = fs.readFileSync(path.join(repositoryRoot, "index.html"), "utf8");

  assert.equal(appCatalog.split(quote).length - 1, 1);
  assert.equal(site.split(quote).length - 1, 2);
});
