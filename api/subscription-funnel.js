const crypto = require("node:crypto");
const { get, list } = require("@vercel/blob");
const { summarize } = require("./_app-store-notifications");

function applyHeaders(res) {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
}

function authorized(req) {
  const expected = String(process.env.SUBSCRIPTION_DASHBOARD_TOKEN || "");
  const supplied = String(req.headers?.authorization || "").replace(/^Bearer\s+/i, "");
  if (!expected || !supplied) return false;
  const expectedBuffer = Buffer.from(expected);
  const suppliedBuffer = Buffer.from(supplied);
  return expectedBuffer.length === suppliedBuffer.length
    && crypto.timingSafeEqual(expectedBuffer, suppliedBuffer);
}

async function readAllRecords() {
  const records = [];
  let cursor;
  do {
    const page = await list({ prefix: "subscription-events/", cursor, limit: 1000 });
    for (const blob of page.blobs) {
      const result = await get(blob.url, { access: "private", useCache: false });
      if (!result || result.statusCode !== 200 || !result.stream) continue;
      records.push(await new Response(result.stream).json());
    }
    cursor = page.hasMore ? page.cursor : undefined;
  } while (cursor);
  return records;
}

module.exports = async function handler(req, res) {
  applyHeaders(res);

  if (req.method !== "GET") {
    res.statusCode = 405;
    res.setHeader("Allow", "GET");
    res.end(JSON.stringify({ error: "method_not_allowed" }));
    return;
  }
  if (!authorized(req)) {
    res.statusCode = 401;
    res.setHeader("WWW-Authenticate", "Bearer");
    res.end(JSON.stringify({ error: "unauthorized" }));
    return;
  }

  try {
    res.statusCode = 200;
    res.end(JSON.stringify(summarize(await readAllRecords())));
  } catch (error) {
    console.error("subscription_funnel_failed", {
      name: error instanceof Error ? error.name : "UnknownError",
      message: error instanceof Error ? error.message : "unknown"
    });
    res.statusCode = 503;
    res.end(JSON.stringify({ error: "subscription_funnel_unavailable" }));
  }
};
