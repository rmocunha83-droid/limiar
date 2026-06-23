const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_DAILY_GENERATION_LIMIT,
  DEFAULT_MODEL,
  buildContextPrompt,
  depthGuidance,
  depthOutputTokenLimit,
  enforceAIDailyLimit,
  enforceAIRateLimit,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  validateReflection,
  validateSpiritualReading
} = require("../api/_limiar-ai");

test("keeps GPT-4.1 mini as the default commercial model", () => {
  assert.equal(DEFAULT_MODEL, "gpt-4.1-mini");
});

test("keeps six remote generations as the default daily limit", () => {
  assert.equal(DEFAULT_DAILY_GENERATION_LIMIT, 6);
});

test("validates a complete reflection payload", () => {
  const reflection = validateReflection({
    reference: "Salmo 23",
    passageText: "O Senhor é meu pastor.",
    homily: "Uma leitura breve e acolhedora.",
    spiritualMeaning: "O trecho recorda cuidado e direção.",
    practicalApplication: "Respire antes de abrir o app.",
    conclusion: "Atravesse com presença.",
    meditationQuestion: "Que escolha protege sua atenção agora?"
  });

  assert.equal(reflection.reference, "Salmo 23");
  assert.equal(reflection.meditationQuestion.endsWith("?"), true);
});

test("rejects invalid reflection payloads", () => {
  assert.throws(() => validateReflection({
    reference: "Salmo 23",
    passageText: "O Senhor é meu pastor.",
    homily: "",
    spiritualMeaning: "x",
    practicalApplication: "x",
    conclusion: "x",
    meditationQuestion: "x"
  }));
});

test("validates spiritual reading items", () => {
  const reading = validateSpiritualReading({
    items: [
      {
        reference: "João 15",
        passageText: "Permanecei em mim.",
        homily: "A passagem chama a permanecer no essencial.",
        spiritualMeaning: "Permanecer é ordenar a atenção.",
        practicalApplication: "Volte ao app com escolha clara.",
        conclusion: "A pausa protege a liberdade.",
        meditationQuestion: "O que merece permanência hoje?"
      }
    ]
  });

  assert.equal(reading.items.length, 1);
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

test("can enforce a daily remote AI generation limit", () => {
  const previousLimit = process.env.LIMIAR_AI_DAILY_GENERATION_LIMIT;
  process.env.LIMIAR_AI_DAILY_GENERATION_LIMIT = "2";

  const req = {
    headers: {
      "x-limiar-client-id": `daily-${Date.now()}-${Math.random()}`
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

  assert.equal(enforceAIDailyLimit(req, res, "spiritual-reading").allowed, true);
  assert.equal(enforceAIDailyLimit(req, res, "spiritual-reading").allowed, true);
  assert.equal(enforceAIDailyLimit(req, res, "spiritual-reading").allowed, false);
  assert.equal(res.statusCode, 429);
  assert.match(res.body, /ai_daily_limit_reached/);

  if (previousLimit === undefined) {
    delete process.env.LIMIAR_AI_DAILY_GENERATION_LIMIT;
  } else {
    process.env.LIMIAR_AI_DAILY_GENERATION_LIMIT = previousLimit;
  }
});

test("normalizes request context without personal identifiers", () => {
  const profile = normalizeProfile({
    tradition: "Católica",
    traditionID: "catholic",
    favoriteSections: ["Salmos"],
    favoriteSectionIDs: ["psalms"],
    favoriteBooks: ["João"],
    favoriteBookIDs: ["john"],
    favoriteThemes: ["Presença"],
    favoriteThemeIDs: ["presence"],
    explanationDepth: "Mais profunda",
    avoidedSections: ["Cartas de Paulo"],
    avoidedBooks: ["Romanos"],
    toneGuidance: "Tom pastoral."
  });
  const passages = normalizePassages([
    {
      id: "psalm-23",
      title: "O Senhor conduz",
      reference: "Salmo 23",
      text: "O Senhor é meu pastor.",
      theme: "Esperança",
      section: "Salmos",
      book: "Salmos"
    }
  ]);
  const recentReflections = normalizeRecentReflections([
    {
      reference: "Salmo 23",
      summary: "Resumo anterior",
      meditationQuestion: "Pergunta anterior?"
    }
  ]);
  const prompt = buildContextPrompt({ profile, passages, recentReflections });

  assert.match(prompt, /Tradição: Católica/);
  assert.match(prompt, /Profundidade: grande/);
  assert.match(prompt, /Profundidade mais profunda/);
  assert.match(prompt, /2 a 3 parágrafos/);
  assert.match(prompt, /IDs dos temas preferidos: presence/);
  assert.match(prompt, /Evitar livros incompatíveis: Romanos/);
  assert.match(prompt, /Regras obrigatórias de personalização/);
  assert.match(prompt, /Resumo anterior/);
  assert.doesNotMatch(prompt, /email|userId|deviceToken/i);
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
    depthOutputTokenLimit("grande", "spiritual-reading") > depthOutputTokenLimit("grande", "reflection"),
    true
  );
});
