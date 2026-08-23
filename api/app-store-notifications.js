const { put } = require("@vercel/blob");
const {
  makeSafeRecord,
  recordPath,
  verifyNotification
} = require("./_app-store-notifications");

function applyHeaders(res) {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
}

function parseBody(req) {
  if (typeof req.body === "object" && req.body !== null) return req.body;
  if (typeof req.body === "string" && req.body.trim()) return JSON.parse(req.body);
  return {};
}

module.exports = async function handler(req, res) {
  applyHeaders(res);

  if (req.method !== "POST") {
    res.statusCode = 405;
    res.setHeader("Allow", "POST");
    res.end(JSON.stringify({ error: "method_not_allowed" }));
    return;
  }

  try {
    const signedPayload = String(parseBody(req).signedPayload || "").trim();
    if (!signedPayload || signedPayload.length > 2_000_000) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "invalid_signed_payload" }));
      return;
    }

    const verified = await verifyNotification(signedPayload);
    const record = makeSafeRecord(verified);
    await put(recordPath(record), JSON.stringify(record), {
      access: "private",
      addRandomSuffix: false,
      allowOverwrite: true,
      contentType: "application/json",
      cacheControlMaxAge: 60
    });

    res.statusCode = 200;
    res.end(JSON.stringify({ ok: true }));
  } catch (error) {
    console.error("app_store_notification_failed", {
      name: error instanceof Error ? error.name : "UnknownError",
      message: error instanceof Error ? error.message : "unknown"
    });
    res.statusCode = 503;
    res.setHeader("Retry-After", "60");
    res.end(JSON.stringify({ error: "notification_processing_failed" }));
  }
};
