const {
  SESSION_ITEM_COUNT,
  applyCommonHeaders,
  assembleReadingItems,
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
  requirePost,
  selectSessionPassages,
  selectionSeed,
  spiritualReadingExplanationSchema,
  validateExplanationItems
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

    const itemCount = Math.min(SESSION_ITEM_COUNT, passages.length);
    const selection = selectSessionPassages({
      profile,
      passages,
      recentPassageIDs,
      count: itemCount,
      seed: selectionSeed(rateLimit.context)
    });

    logAIDiagnostic("spiritual_reading_passages_selected", {
      endpoint: "spiritual-reading",
      requestID: rateLimit.context.requestID,
      clientID: rateLimit.context.clientID,
      tradition: profile.tradition,
      depth: profile.explanationDepth,
      favoriteBooks: profile.favoriteBooks.join(", "),
      selectedReferences: selection.selected.map((passage) => passage.reference).join(" + "),
      selectionTier: selection.selectionTier,
      reusedRecentCount: selection.reusedRecentCount,
      priorityCount: selection.priorityCount,
      favoriteThemeCount: selection.favoriteThemeCount,
      freshCount: selection.freshCount,
      candidateCount: selection.candidateCount
    });

    const prompt = buildExplanationPrompt({
      profile,
      selectedPassages: selection.selected,
      recentReflections,
      includeReflection: false
    });

    const result = await callTextModel({
      schema: spiritualReadingExplanationSchema(itemCount),
      schemaName: "limiar_spiritual_reading",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "spiritual-reading"),
      debugContext: {
        endpoint: "spiritual-reading",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        depth: profile.explanationDepth,
        tradition: profile.tradition,
        passagesCount: selection.selected.length
      }
    });

    const explanations = validateExplanationItems(result, itemCount);

    res.statusCode = 200;
    res.end(JSON.stringify({
      items: assembleReadingItems(selection.selected, explanations)
    }));
  } catch (error) {
    logAIError("spiritual-reading", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_spiritual_reading_failed" }));
  }
};
