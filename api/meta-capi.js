const META_PIXEL_ID = "1567751021802834";
const META_GRAPH_VERSION = "v22.0";
const WEB_EVENTS = new Set(["PageView", "ViewContent", "Lead"]);

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

function trimText(value, maxLength = 2048) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function clientIP(req) {
  return trimText(req.headers?.["x-forwarded-for"] || "", 120).split(",")[0].trim();
}

function validEventTime(value) {
  const eventTime = Number(value);
  const now = Math.floor(Date.now() / 1000);
  if (!Number.isInteger(eventTime) || eventTime < now - 86_400 || eventTime > now + 300) {
    return now;
  }
  return eventTime;
}

module.exports = async function handler(req, res) {
  applyHeaders(res);

  if (req.method !== "POST") {
    res.statusCode = 405;
    res.setHeader("Allow", "POST");
    res.end(JSON.stringify({ error: "method_not_allowed" }));
    return;
  }

  const token = trimText(process.env.META_CAPI_ACCESS_TOKEN, 512);
  if (!token) {
    res.statusCode = 503;
    res.end(JSON.stringify({ error: "meta_capi_not_configured" }));
    return;
  }

  try {
    const body = parseBody(req);
    const eventName = trimText(body.eventName, 80);
    const eventID = trimText(body.eventID, 160);
    const eventSourceURL = trimText(body.eventSourceURL, 2048);

    if (!WEB_EVENTS.has(eventName) || !eventID || !eventSourceURL.startsWith("https://limiar-five.vercel.app/")) {
      res.statusCode = 400;
      res.end(JSON.stringify({ error: "invalid_event" }));
      return;
    }

    const userData = {
      client_ip_address: clientIP(req),
      client_user_agent: trimText(req.headers?.["user-agent"] || "", 512)
    };
    const fbp = trimText(body.fbp, 256);
    const fbc = trimText(body.fbc, 256);
    if (fbp) userData.fbp = fbp;
    if (fbc) userData.fbc = fbc;

    const metaResponse = await fetch(
      `https://graph.facebook.com/${META_GRAPH_VERSION}/${META_PIXEL_ID}/events?access_token=${encodeURIComponent(token)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          data: [{
            event_name: eventName,
            event_time: validEventTime(body.eventTime),
            action_source: "website",
            event_source_url: eventSourceURL,
            event_id: eventID,
            user_data: userData,
            custom_data: eventName === "Lead" ? { content_name: "app_store_download_click" } : undefined
          }]
        })
      }
    );

    if (!metaResponse.ok) {
      const errorPayload = await metaResponse.json().catch(() => ({}));
      const metaError = errorPayload?.error || {};
      console.error("meta_capi_request_failed", {
        status: metaResponse.status,
        eventName,
        code: metaError.code,
        subcode: metaError.error_subcode,
        type: metaError.type,
        message: metaError.message
      });
      res.statusCode = 502;
      res.end(JSON.stringify({ error: "meta_capi_request_failed" }));
      return;
    }

    res.statusCode = 204;
    res.end();
  } catch (error) {
    console.error("meta_capi_unexpected_error", { message: error instanceof Error ? error.message : "unknown" });
    res.statusCode = 500;
    res.end(JSON.stringify({ error: "meta_capi_unexpected_error" }));
  }
};
