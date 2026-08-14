const test = require("node:test");
const assert = require("node:assert/strict");
const {
  makeSafeRecord,
  recordPath,
  subscriberKey,
  summarize
} = require("../api/_app-store-notifications");

test("safe record keeps lifecycle fields without raw transaction identifiers", () => {
  const record = makeSafeRecord({
    notification: {
      notificationUUID: "notification-1",
      notificationType: "SUBSCRIBED",
      subtype: "INITIAL_BUY",
      signedDate: Date.UTC(2026, 7, 14),
      data: { environment: "Production" }
    },
    transaction: {
      originalTransactionId: "raw-original-transaction-id",
      transactionId: "raw-transaction-id",
      productId: "limiar_premium_monthly",
      offerType: 1,
      offerDiscountType: "FREE_TRIAL"
    },
    renewal: { autoRenewStatus: 1 }
  }, "test-secret");

  assert.equal(record.subscriberKey, subscriberKey("raw-original-transaction-id", "test-secret"));
  assert.equal(record.productId, "limiar_premium_monthly");
  assert.equal(record.offerDiscountType, "FREE_TRIAL");
  assert.equal(Object.hasOwn(record, "transactionId"), false);
  assert.equal(Object.hasOwn(record, "originalTransactionId"), false);
  assert.equal(
    recordPath(record),
    "subscription-events/production/2026-08-14/notification-1.json"
  );
});

test("summary calculates verified trial conversion by pseudonymous subscription", () => {
  const base = {
    environment: "Production",
    signedDate: Date.UTC(2026, 7, 14),
    subscriberKey: "subscription-a"
  };
  const summary = summarize([
    {
      ...base,
      notificationType: "SUBSCRIBED",
      subtype: "INITIAL_BUY",
      offerType: 1,
      offerDiscountType: "FREE_TRIAL"
    },
    {
      ...base,
      signedDate: Date.UTC(2026, 7, 21),
      notificationType: "DID_RENEW"
    },
    {
      ...base,
      notificationType: "DID_CHANGE_RENEWAL_STATUS",
      subtype: "AUTO_RENEW_DISABLED"
    },
    {
      ...base,
      environment: "Sandbox",
      subscriberKey: "sandbox-subscription",
      notificationType: "SUBSCRIBED"
    }
  ]);

  assert.equal(summary.productionNotifications, 3);
  assert.equal(summary.uniqueSubscriptions, 1);
  assert.equal(summary.trials, 1);
  assert.equal(summary.convertedTrials, 1);
  assert.equal(summary.trialConversionRate, 1);
  assert.equal(summary.renewalDisabled, 1);
});
