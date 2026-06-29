const {
  applyCommonHeaders,
  buildContextPrompt,
  callGLM,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  logAIDiagnostic,
  logAIError,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  parseBody,
  reflectionSchema,
  requirePost,
  validateReflection
} = require("./_limiar-ai");

module.exports = async function handler(req, res) {
  applyCommonHeaders(res);
  if (!requirePost(req, res)) return;
  const rateLimit = enforceAIRateLimit(req, res, "reflection");
  if (!rateLimit.allowed) return;

  try {
    const body = parseBody(req);
    const profile = normalizeProfile(body.profile);
    const passages = normalizePassages(body.passages);
    const recentReflections = normalizeRecentReflections(body.recentReflections);

    if (!passages.length) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "missing_passage" }));
      return;
    }

    const prompt = [
      buildContextPrompt({ profile, passages, recentReflections }),
      "",
      "Gere uma única reflexão para o conjunto de trechos. Use estes campos:",
      "reference, passageText, homily, spiritualMeaning, practicalApplication, conclusion, meditationQuestion.",
      "A homily deve resumir o eixo espiritual da leitura.",
      "O spiritualMeaning deve ser o bloco principal e respeitar claramente a profundidade escolhida.",
      "A practicalApplication deve nascer do trecho e dos temas preferidos, com ação concreta para o próximo período de uso dos apps.",
      "A conclusion deve ser específica, não uma frase fixa reaproveitada.",
      "A pergunta final deve ser nova em relação ao histórico recente."
    ].join("\n");

    logAIDiagnostic("reflection_preferences_loaded", {
      endpoint: "reflection",
      requestID: rateLimit.context.requestID,
      clientID: rateLimit.context.clientID,
      tradition: profile.tradition,
      depth: profile.explanationDepth,
      favoriteThemes: profile.favoriteThemes.join(", "),
      favoriteBooks: profile.favoriteBooks.join(", "),
      favoriteSections: profile.favoriteSections.join(", "),
      passagesCount: passages.length
    });

    const result = await callGLM({
      schema: reflectionSchema,
      schemaName: "limiar_reflection",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "reflection"),
      debugContext: {
        endpoint: "reflection",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        depth: profile.explanationDepth,
        tradition: profile.tradition,
        favoriteThemesCount: profile.favoriteThemes.length,
        favoriteBooksCount: profile.favoriteBooks.length,
        favoriteSectionsCount: profile.favoriteSections.length,
        passagesCount: passages.length
      }
    });

    res.statusCode = 200;
    res.end(JSON.stringify(validateReflection(result)));
  } catch (error) {
    logAIError("reflection", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_reflection_failed" }));
  }
};
