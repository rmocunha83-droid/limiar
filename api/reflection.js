const {
  applyCommonHeaders,
  buildContextPrompt,
  callOpenAI,
  enforceAIDailyLimit,
  enforceAIRateLimit,
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
  const dailyLimit = enforceAIDailyLimit(req, res, "reflection");
  if (!dailyLimit.allowed) return;

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
      "A pergunta final deve ser nova em relação ao histórico recente."
    ].join("\n");

    const result = await callOpenAI({
      schema: reflectionSchema,
      schemaName: "limiar_reflection",
      prompt,
      maxOutputTokens: profile.explanationDepth === "grande" ? 1400 : 900
    });

    res.statusCode = 200;
    res.end(JSON.stringify(validateReflection(result)));
  } catch (error) {
    logAIError("reflection", error, dailyLimit.context);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_reflection_failed" }));
  }
};
