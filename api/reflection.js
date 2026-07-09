const {
  applyCommonHeaders,
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
  reflectionExplanationSchema,
  requirePost,
  validateExplanationFields
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

    // Os trechos já vêm definidos pelo cliente: a IA gera apenas a reflexão.
    const prompt = [
      buildExplanationPrompt({
        profile,
        selectedPassages: passages,
        recentReflections,
        includeReflection: false
      }),
      "",
      "Tarefa única: gere UMA reflexão para o conjunto dos trechos acima, com os campos",
      "homily, spiritualMeaning, practicalApplication, conclusion e meditationQuestion.",
      "A homily deve resumir o eixo espiritual da leitura.",
      "O spiritualMeaning deve ser o bloco principal e respeitar claramente a profundidade escolhida.",
      "A practicalApplication deve nascer dos trechos e dos temas preferidos, com ação concreta para o restante do dia.",
      "A conclusion deve ser específica, não uma frase fixa reaproveitada.",
      "A meditationQuestion deve ser nova em relação ao histórico recente."
    ].join("\n");

    logAIDiagnostic("reflection_preferences_loaded", {
      endpoint: "reflection",
      requestID: rateLimit.context.requestID,
      clientID: rateLimit.context.clientID,
      tradition: profile.tradition,
      depth: profile.explanationDepth,
      passagesCount: passages.length
    });

    const result = await callTextModel({
      schema: reflectionExplanationSchema,
      schemaName: "limiar_reflection",
      prompt,
      maxOutputTokens: depthOutputTokenLimit(profile.explanationDepth, "reflection"),
      debugContext: {
        endpoint: "reflection",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID,
        depth: profile.explanationDepth,
        tradition: profile.tradition,
        passagesCount: passages.length
      }
    });

    const reflection = validateExplanationFields(result, "reflection");

    res.statusCode = 200;
    res.end(JSON.stringify(assembleReflection(passages, reflection)));
  } catch (error) {
    logAIError("reflection", error, rateLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_reflection_failed" }));
  }
};
