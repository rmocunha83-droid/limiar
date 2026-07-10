const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_MODEL,
  DEFAULT_REASONING_EFFORT,
  DEFAULT_TTS_MODEL,
  DEFAULT_TTS_VOICE_ID,
  DEFAULT_TTS_SPEED,
  SESSION_ITEM_COUNT,
  assembleReadingItems,
  assembleReflection,
  buildExplanationPrompt,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  normalizeSpeechInput,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  parseProviderJSON,
  readingSessionExplanationSchema,
  selectSessionPassages,
  validateExplanationFields,
  validateExplanationItems
} = require("../api/_limiar-ai");

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

test("keeps GPT-5.4 mini as the default commercial text model", () => {
  assert.equal(DEFAULT_MODEL, "gpt-5.4-mini");
  assert.equal(DEFAULT_REASONING_EFFORT, "none");
});

test("keeps ElevenLabs Flash as the economical default voice model", () => {
  assert.equal(DEFAULT_TTS_MODEL, "eleven_flash_v2_5");
  assert.equal(DEFAULT_TTS_VOICE_ID, "21m00Tcm4TlvDq8ikWAM");
  assert.equal(DEFAULT_TTS_SPEED, 0.92);
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
    /missing_homily/
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

test("normalizes depth synonyms and changes guidance clearly", () => {
  assert.equal(normalizeProfile({ explanationDepth: "curta" }).explanationDepth, "curta");
  assert.equal(normalizeProfile({ explanationDepth: "média" }).explanationDepth, "média");
  assert.equal(normalizeProfile({ explanationDepth: "Mais profunda" }).explanationDepth, "grande");
  assert.match(depthGuidance("curta"), /1 parágrafo breve/);
  assert.match(depthGuidance("média"), /1 a 2 parágrafos/);
  assert.match(depthGuidance("grande"), /2 a 3 parágrafos/);
});

test("uses different output budgets by depth and endpoint", () => {
  assert.equal(depthOutputTokenLimit("curta", "reflection") < depthOutputTokenLimit("média", "reflection"), true);
  assert.equal(depthOutputTokenLimit("média", "reflection") < depthOutputTokenLimit("grande", "reflection"), true);
  assert.equal(
    depthOutputTokenLimit("grande", "reading-session") > depthOutputTokenLimit("grande", "reflection"),
    true
  );
});
