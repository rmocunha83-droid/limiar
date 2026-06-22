const {
  applyCommonHeaders,
  buildContextPrompt,
  callOpenAI,
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
      "Gere um item de leitura para cada trecho enviado, até 5 itens quando houver 5 ou mais trechos.",
      "Cada item deve usar os campos reference, passageText, homily, spiritualMeaning, practicalApplication, conclusion, meditationQuestion.",
      "Use passageText exatamente baseado no trecho enviado; não invente versículos."
    ].join("\n");

    const result = await callOpenAI({
      schema: spiritualReadingSchema,
      schemaName: "limiar_spiritual_reading",
      prompt,
      maxOutputTokens: profile.explanationDepth === "grande" ? 3200 : 2200
    });

    res.statusCode = 200;
    res.end(JSON.stringify(validateSpiritualReading(result)));
  } catch (error) {
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_spiritual_reading_failed" }));
  }
};
