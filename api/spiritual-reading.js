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
  requirePost,
  spiritualReadingSchema,
  validateSpiritualReading
} = require("./_limiar-ai");

module.exports = async function handler(req, res) {
  applyCommonHeaders(res);
  if (!requirePost(req, res)) return;
  const rateLimit = enforceAIRateLimit(req, res, "spiritual-reading");
  if (!rateLimit.allowed) return;

  try {
    const body = parseBody(req);
    const profile = normalizeProfile(body.profile);
    const passages = normalizePassages(body.passages);
    const recentPassageIDs = Array.isArray(body.recentPassageIDs) ? body.recentPassageIDs : [];
    const recentReflections = normalizeRecentReflections(body.recentReflections);

    if (!passages.length) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "missing_passages" }));
      return;
    }

    const prompt = [
      buildContextPrompt({ profile, passages, recentPassageIDs, recentReflections }),
      "",
      "Selecione exatamente 3 itens dentre os trechos disponíveis enviados.",
      "Cada item deve usar os campos reference, passageText, homily, spiritualMeaning, practicalApplication, conclusion, meditationQuestion.",
      "Use passageText exatamente baseado em um dos trechos enviados; não invente versículos nem altere a tradição.",
      "Não use sempre os primeiros trechos: escolha os 3 que melhor combinam com a tradição, livros, seções, temas e histórico recente.",
      "Evite referências presentes em Trechos recentes a evitar, salvo se não houver alternativa coerente.",
      "A homily deve variar de tamanho conforme a profundidade escolhida.",
      "O spiritualMeaning deve explicar o sentido espiritual do trecho e se conectar aos temas preferidos.",
      "A practicalApplication e a conclusion devem ser concretas, específicas e diferentes entre os 3 itens."
    ].join("\n");

    logAIDiagnostic("spiritual_reading_preferences_loaded", {
      endpoint: "spiritual-reading",
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
      schema: spiritualReadingSchema,
      schemaName: "limiar_spiritual_reading",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "spiritual-reading"),
      debugContext: {
        endpoint: "spiritual-reading",
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
    res.end(JSON.stringify(validateSpiritualReading(result, 3)));
  } catch (error) {
    logAIError("spiritual-reading", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_spiritual_reading_failed" }));
  }
};
