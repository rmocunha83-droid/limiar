const {
  applyCommonHeaders,
  assembleReadingItems,
  assembleReflection,
  buildExplanationPrompt,
  callTextModel,
  depthOutputTokenLimit,
  enforceAIRateLimit,
  logAIDiagnostic,
  logAIError,
  normalizePassages,
  normalizeProfile,
  normalizeRecentReflections,
  parseBody,
  readingSessionExplanationSchema,
  requirePost,
  resolveReadingSessionOptions,
  selectSessionPassages,
  selectionSeed,
  validateExplanationFields,
  validateExplanationItems
} = require("./_limiar-ai");

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

    const sessionOptions = resolveReadingSessionOptions(
      body,
      profile.explanationDepth,
      passages.length
    );
    const itemCount = sessionOptions.itemCount;

    // Seleção determinística: o servidor fixa os trechos respeitando as
    // preferências e rotacionando contra o histórico. Sem itemCount, mantém o
    // contrato publicado de três itens e da profundidade antiga.
    const selection = selectSessionPassages({
      profile,
      passages,
      recentPassageIDs,
      count: itemCount,
      seed: selectionSeed(rateLimit.context)
    });

    logAIDiagnostic("reading_session_passages_selected", {
      endpoint: "reading-session",
      requestID: rateLimit.context.requestID,
      clientID: rateLimit.context.clientID,
      tradition: profile.tradition,
      depth: profile.explanationDepth,
      generationDepth: sessionOptions.generationDepth,
      requestedItemCount: sessionOptions.requestedItemCount,
      adaptiveItemCount: sessionOptions.hasItemCount,
      favoriteBooks: profile.favoriteBooks.join(", "),
      selectedReferences: selection.selected.map((passage) => passage.reference).join(" + "),
      selectionTier: selection.selectionTier,
      reusedRecentCount: selection.reusedRecentCount,
      priorityCount: selection.priorityCount,
      favoriteThemeCount: selection.favoriteThemeCount,
      freshCount: selection.freshCount,
      candidateCount: selection.candidateCount
    });

    const generationProfile = {
      ...profile,
      explanationDepth: sessionOptions.generationDepth
    };
    const prompt = buildExplanationPrompt({
      profile: generationProfile,
      selectedPassages: selection.selected,
      recentReflections,
      includeReflection: true
    });

    const result = await callTextModel({
      schema: readingSessionExplanationSchema(itemCount),
      schemaName: "limiar_reading_session",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(sessionOptions.outputBudgetDepth, "reading-session"),
      debugContext: {
        endpoint: "reading-session",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        depth: sessionOptions.generationDepth,
        requestedItemCount: sessionOptions.requestedItemCount,
        adaptiveItemCount: sessionOptions.hasItemCount,
        tradition: profile.tradition,
        passagesCount: selection.selected.length
      }
    });

    const explanations = validateExplanationItems(result, itemCount);
    const reflection = validateExplanationFields(result.reflection, "reflection");

    res.statusCode = 200;
    res.end(JSON.stringify({
      items: assembleReadingItems(selection.selected, explanations),
      reflection: assembleReflection(selection.selected, reflection)
    }));
  } catch (error) {
    logAIError("reading-session", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_reading_session_failed" }));
  }
};
