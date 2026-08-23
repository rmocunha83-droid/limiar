const crypto = require("node:crypto");
const {
  Environment,
  SignedDataVerifier
} = require("@apple/app-store-server-library");

const APP_APPLE_ID = 6783115468;
const BUNDLE_ID = "com.romeucunha.Limiar";

function requiredEnv(name) {
  const value = String(process.env[name] || "").trim();
  if (!value) throw new Error(`missing_${name.toLowerCase()}`);
  return value;
}

function loadRootCertificates() {
  const encoded = JSON.parse(requiredEnv("APPLE_ROOT_CA_BASE64_JSON"));
  if (!Array.isArray(encoded) || encoded.length === 0) {
    throw new Error("invalid_apple_root_ca_base64_json");
  }
  return encoded.map((certificate) => Buffer.from(certificate, "base64"));
}

function createVerifiers() {
  const roots = loadRootCertificates();
  return [
    new SignedDataVerifier(
      roots,
      true,
      Environment.PRODUCTION,
      BUNDLE_ID,
      APP_APPLE_ID
    ),
    new SignedDataVerifier(
      roots,
      true,
      Environment.SANDBOX,
      BUNDLE_ID,
      undefined
    )
  ];
}

async function verifyNotification(signedPayload, verifiers = createVerifiers()) {
  let lastError;
  for (const verifier of verifiers) {
    try {
      const notification = await verifier.verifyAndDecodeNotification(signedPayload);
      const transaction = notification.data?.signedTransactionInfo
        ? await verifier.verifyAndDecodeTransaction(notification.data.signedTransactionInfo)
        : undefined;
      const renewal = notification.data?.signedRenewalInfo
        ? await verifier.verifyAndDecodeRenewalInfo(notification.data.signedRenewalInfo)
        : undefined;
      return { notification, transaction, renewal };
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError || new Error("notification_verification_failed");
}

function subscriberKey(originalTransactionId, secret = requiredEnv("SUBSCRIPTION_EVENT_HASH_SECRET")) {
  if (!originalTransactionId) return undefined;
  return crypto
    .createHmac("sha256", secret)
    .update(String(originalTransactionId))
    .digest("hex")
    .slice(0, 32);
}

function safeEnum(value) {
  return value === undefined || value === null ? undefined : String(value);
}

function compact(object) {
  return Object.fromEntries(
    Object.entries(object).filter(([, value]) => value !== undefined && value !== null)
  );
}

function makeSafeRecord(
  { notification, transaction, renewal },
  hashSecret = requiredEnv("SUBSCRIPTION_EVENT_HASH_SECRET")
) {
  const originalTransactionId = transaction?.originalTransactionId
    || renewal?.originalTransactionId;

  return compact({
    schemaVersion: 1,
    notificationUUID: notification.notificationUUID,
    notificationType: safeEnum(notification.notificationType),
    subtype: safeEnum(notification.subtype),
    environment: safeEnum(notification.data?.environment),
    signedDate: notification.signedDate,
    subscriberKey: subscriberKey(originalTransactionId, hashSecret),
    productId: transaction?.productId || renewal?.productId,
    transactionReason: safeEnum(transaction?.transactionReason),
    offerType: transaction?.offerType ?? renewal?.offerType,
    offerDiscountType: safeEnum(
      transaction?.offerDiscountType ?? renewal?.offerDiscountType
    ),
    purchaseDate: transaction?.purchaseDate,
    expiresDate: transaction?.expiresDate,
    revocationDate: transaction?.revocationDate,
    autoRenewStatus: renewal?.autoRenewStatus,
    expirationIntent: renewal?.expirationIntent,
    isInBillingRetryPeriod: renewal?.isInBillingRetryPeriod,
    gracePeriodExpiresDate: renewal?.gracePeriodExpiresDate,
    renewalDate: renewal?.renewalDate
  });
}

function recordPath(record) {
  if (!record.notificationUUID) throw new Error("missing_notification_uuid");
  const date = new Date(record.signedDate || Date.now()).toISOString().slice(0, 10);
  const environment = String(record.environment || "unknown").toLowerCase();
  return `subscription-events/${environment}/${date}/${record.notificationUUID}.json`;
}

function summarize(records) {
  const production = records.filter((record) => record.environment === "Production");
  const byType = {};
  const subscribers = new Map();

  for (const record of production) {
    const key = `${record.notificationType || "UNKNOWN"}:${record.subtype || "NONE"}`;
    byType[key] = (byType[key] || 0) + 1;

    if (!record.subscriberKey) continue;
    const lifecycle = subscribers.get(record.subscriberKey) || {
      trialStarted: false,
      renewedAfterTrial: false,
      renewalDisabled: false,
      expired: false,
      refunded: false
    };
    if (record.offerType === 1 && record.offerDiscountType === "FREE_TRIAL") {
      lifecycle.trialStarted = true;
    }
    if (lifecycle.trialStarted && record.notificationType === "DID_RENEW") {
      lifecycle.renewedAfterTrial = true;
    }
    if (
      record.notificationType === "DID_CHANGE_RENEWAL_STATUS"
      && record.subtype === "AUTO_RENEW_DISABLED"
    ) lifecycle.renewalDisabled = true;
    if (record.notificationType === "EXPIRED") lifecycle.expired = true;
    if (["REFUND", "REVOKE"].includes(record.notificationType)) lifecycle.refunded = true;
    subscribers.set(record.subscriberKey, lifecycle);
  }

  const lifecycleRows = [...subscribers.values()];
  const trials = lifecycleRows.filter((row) => row.trialStarted).length;
  const convertedTrials = lifecycleRows.filter((row) => row.renewedAfterTrial).length;

  return {
    generatedAt: new Date().toISOString(),
    dataThrough: production.reduce(
      (latest, record) => Math.max(latest, Number(record.signedDate) || 0),
      0
    ) || null,
    productionNotifications: production.length,
    uniqueSubscriptions: subscribers.size,
    trials,
    convertedTrials,
    trialConversionRate: trials ? convertedTrials / trials : null,
    renewalDisabled: lifecycleRows.filter((row) => row.renewalDisabled).length,
    expired: lifecycleRows.filter((row) => row.expired).length,
    refunded: lifecycleRows.filter((row) => row.refunded).length,
    byType
  };
}

module.exports = {
  createVerifiers,
  makeSafeRecord,
  recordPath,
  subscriberKey,
  summarize,
  verifyNotification
};
