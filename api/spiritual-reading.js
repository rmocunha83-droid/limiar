const {
  applyCommonHeaders,
  buildContextPrompt,
  callTextModel,
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

const DIVERSITY_RETRY_ERRORS = new Set([
  "duplicate_reference",
  "duplicate_passage_text",
  "recent_reference_reused"
]);

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
      "Exclua referências presentes em Trechos recentes a evitar sempre que houver qualquer alternativa da mesma tradição.",
      "Se muitos trechos recentes aparecerem na lista, prefira trechos ainda não usados, mesmo que a correspondência com tema/livro seja um pouco menor.",
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

    let result = await callTextModel({
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

    let validated;
    try {
      validated = validateSpiritualReading(result, 3, { passages, recentPassageIDs });
    } catch (error) {
      if (!DIVERSITY_RETRY_ERRORS.has(error.code)) throw error;

      logAIDiagnostic("spiritual_reading_diversity_retry", {
        endpoint: "spiritual-reading",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        reason: error.code,
        recentPassageIDsCount: recentPassageIDs.length,
        passagesCount: passages.length
      });

      result = await callTextModel({
        schema: spiritualReadingSchema,
        schemaName: "limiar_spiritual_reading_retry",
        prompt: [
          prompt,
          "",
          "Correção obrigatória antes de responder:",
          "- Não repita nenhuma referência nem nenhum texto dentro da resposta.",
          "- Não use trechos recentes se houver alternativas disponíveis.",
          "- Use IDs diferentes entre si e fora da lista recente.",
          "- Mantenha exatamente 3 itens."
        ].join("\n"),
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

      validated = validateSpiritualReading(result, 3, { passages, recentPassageIDs });
    }

    res.statusCode = 200;
    res.end(JSON.stringify(validated));
  } catch (error) {
    logAIError("spiritual-reading", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_spiritual_reading_failed" }));
  }
};
