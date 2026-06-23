const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_MODEL,
  buildContextPrompt,
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

test("normalizes request context without personal identifiers", () => {
  const profile = normalizeProfile({
    tradition: "Católica",
    favoriteSections: ["Salmos"],
    favoriteBooks: ["João"],
    favoriteThemes: ["Presença"],
    explanationDepth: "grande"
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
  assert.match(prompt, /Resumo anterior/);
  assert.doesNotMatch(prompt, /email|userId|deviceToken/i);
});
