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
  readingSessionSchema,
  requirePost,
  validateReadingSession
} = require("./_limiar-ai");

const DIVERSITY_RETRY_ERRORS = new Set([
  "duplicate_reference",
  "duplicate_passage_text",
  "recent_reference_reused"
]);

module.exports = async function handler(req, res) {
  applyCommonHeaders(res);
  if (!requirePost(req, res)) return;
  const rateLimit = enforceAIRateLimit(req, res, "reading-session");
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
      "Gere uma sessão completa de leitura em uma única resposta.",
      "A resposta deve conter exatamente 3 itens em items e uma reflection geral para o conjunto.",
      "",
      "Regras para items:",
      "- Selecione exatamente 3 trechos dentre os trechos disponíveis enviados.",
      "- Use passageText baseado nos trechos enviados; não invente versículos nem altere a tradição.",
      "- Não use sempre os primeiros trechos: escolha os 3 que melhor combinam com tradição, livros, seções, temas e histórico recente.",
      "- Exclua referências presentes em Trechos recentes a evitar sempre que houver qualquer alternativa da mesma tradição.",
      "- Se muitos trechos recentes aparecerem na lista, prefira trechos ainda não usados, mesmo que a correspondência com tema/livro seja um pouco menor.",
      "- Em cada item, homily, spiritualMeaning, practicalApplication, conclusion e meditationQuestion devem ser específicos daquele trecho.",
      "",
      "Regras para reflection:",
      "- Gere uma reflexão única para o conjunto dos 3 trechos.",
      "- A homily deve resumir o eixo espiritual da leitura.",
      "- O spiritualMeaning deve ser o bloco principal e respeitar claramente a profundidade escolhida.",
      "- A practicalApplication deve nascer dos trechos e dos temas preferidos, com uma ação concreta para o restante do dia.",
      "- A conclusion deve ser específica, não uma frase fixa reaproveitada.",
      "- A meditationQuestion deve ser nova em relação ao histórico recente.",
      "",
      "Otimize para resposta rápida: seja completo, mas não prolixo."
    ].join("\n");

    logAIDiagnostic("reading_session_preferences_loaded", {
      endpoint: "reading-session",
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
      schema: readingSessionSchema,
      schemaName: "limiar_reading_session",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "reading-session"),
      debugContext: {
        endpoint: "reading-session",
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
      validated = validateReadingSession(result, 3, { passages, recentPassageIDs });
    } catch (error) {
      if (!DIVERSITY_RETRY_ERRORS.has(error.code)) throw error;

      logAIDiagnostic("reading_session_diversity_retry", {
        endpoint: "reading-session",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        reason: error.code,
        recentPassageIDsCount: recentPassageIDs.length,
        passagesCount: passages.length
      });

      result = await callTextModel({
        schema: readingSessionSchema,
        schemaName: "limiar_reading_session_retry",
        prompt: [
          prompt,
          "",
          "Correção obrigatória antes de responder:",
          "- Não repita nenhuma referência nem nenhum texto dentro da resposta.",
          "- Não use trechos recentes se houver alternativas disponíveis.",
          "- Use IDs diferentes entre si e fora da lista recente.",
          "- Mantenha exatamente 3 itens e uma reflexão geral."
        ].join("\n"),
        maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "reading-session"),
        debugContext: {
          endpoint: "reading-session",
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

      validated = validateReadingSession(result, 3, { passages, recentPassageIDs });
    }

    res.statusCode = 200;
    res.end(JSON.stringify(validated));
  } catch (error) {
    logAIError("reading-session", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_reading_session_failed" }));
  }
};
