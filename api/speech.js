const {
  applyAudioHeaders,
  applyCommonHeaders,
  callOpenAISpeech,
  enforceAIRateLimit,
  logAIError,
  parseBody,
  requirePost
} = require("./_limiar-ai");

module.exports = async function handler(req, res) {
  applyCommonHeaders(res);
  if (!requirePost(req, res)) return;
  const rateLimit = enforceAIRateLimit(req, res, "speech");
  if (!rateLimit.allowed) return;

  try {
    const body = parseBody(req);
    const audio = await callOpenAISpeech({
      input: body.text,
      voice: body.voice,
      instructions: body.instructions,
      debugContext: {
        endpoint: "speech",
        requestID: rateLimit.context.requestID,
        clientID: rateLimit.context.clientID
      }
    });

    applyAudioHeaders(res);
    res.statusCode = 200;
    res.end(audio);
  } catch (error) {
    logAIError("speech", error, rateLimit.context);
    applyCommonHeaders(res);
    res.statusCode = error.statusCode || 502;
    res.end(JSON.stringify({ error: "ai_speech_failed" }));
  }
};
