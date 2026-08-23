import XCTest
@testable import Limiar

final class SubscriptionGateHardeningTests: XCTestCase {
    // MARK: - Telemetria de compra

    func testPurchaseTerminalOutcomesUseExclusiveEvents() {
        let outcomes = LimiarAnalytics.PurchaseTerminalOutcome.allCases
        let eventNames = outcomes.map(\.analyticsEventName)

        XCTAssertEqual(Set(eventNames).count, outcomes.count)
        XCTAssertEqual(
            LimiarAnalytics.PurchaseTerminalOutcome.cancelled.analyticsEventName,
            "purchase_cancelled"
        )
        XCTAssertEqual(
            LimiarAnalytics.PurchaseTerminalOutcome.failed.analyticsEventName,
            "purchase_failed"
        )
        XCTAssertNotEqual(
            LimiarAnalytics.PurchaseTerminalOutcome.cancelled.analyticsEventName,
            LimiarAnalytics.PurchaseTerminalOutcome.failed.analyticsEventName
        )
    }

    func testTrialReminderDoesNotTouchNotificationCenterInUnitTests() {
        XCTAssertFalse(TrialReminderRuntimePolicy.shouldSync(isRunningUnitTests: true))
        XCTAssertTrue(TrialReminderRuntimePolicy.shouldSync(isRunningUnitTests: false))
    }

    // MARK: - Banner de reativação

    func testWinbackAppearsOnlyForNewActiveSubscriptionWithRenewalOff() {
        XCTAssertEqual(
            SubscriptionWinbackPolicy.phase(
                cohort: .new,
                hasActiveSubscription: true,
                autoRenewIsOff: true,
                isIntroductoryTrial: true
            ),
            .trial
        )
        XCTAssertEqual(
            SubscriptionWinbackPolicy.phase(
                cohort: .new,
                hasActiveSubscription: true,
                autoRenewIsOff: true,
                isIntroductoryTrial: false
            ),
            .paid
        )

        XCTAssertNil(
            SubscriptionWinbackPolicy.phase(
                cohort: .legacy,
                hasActiveSubscription: true,
                autoRenewIsOff: true,
                isIntroductoryTrial: true
            )
        )
        XCTAssertNil(
            SubscriptionWinbackPolicy.phase(
                cohort: .new,
                hasActiveSubscription: false,
                autoRenewIsOff: true,
                isIntroductoryTrial: true
            )
        )
        XCTAssertNil(
            SubscriptionWinbackPolicy.phase(
                cohort: .new,
                hasActiveSubscription: true,
                autoRenewIsOff: false,
                isIntroductoryTrial: true
            )
        )
    }

    func testWinbackRemainingPeriodTextUsesCalendarDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Sao_Paulo"))
        let now = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 8, day: 8, hour: 23, minute: 30))
        )

        XCTAssertEqual(
            SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: calendar.date(byAdding: .minute, value: 20, to: now),
                now: now,
                calendar: calendar
            ),
            "hoje"
        )
        XCTAssertEqual(
            SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: calendar.date(byAdding: .hour, value: 2, to: now),
                now: now,
                calendar: calendar
            ),
            "em 1 dia"
        )
        XCTAssertEqual(
            SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: calendar.date(byAdding: .day, value: 4, to: now),
                now: now,
                calendar: calendar
            ),
            "em 4 dias"
        )
        XCTAssertEqual(
            SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: now.addingTimeInterval(-60),
                now: now,
                calendar: calendar
            ),
            "hoje"
        )
        XCTAssertEqual(
            SubscriptionWinbackPolicy.remainingPeriodText(
                endsAt: nil,
                now: now,
                calendar: calendar
            ),
            "hoje"
        )
    }

    // MARK: - Classificação de coorte na primeira execução

    func testKeychainTrialMarkerAlwaysWinsAsLegacy() {
        let resolution = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: true,
            persistedDecision: nil,
            hadCompletedOnboardingBeforeGate: false
        )
        XCTAssertEqual(resolution.cohort, .legacy)
        XCTAssertEqual(resolution.decisionToPersist, .legacy)
    }

    func testPersistedDecisionIsStable() {
        let asNew = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: false,
            persistedDecision: .new,
            hadCompletedOnboardingBeforeGate: true
        )
        XCTAssertEqual(asNew.cohort, .new)
        XCTAssertNil(asNew.decisionToPersist)

        let asLegacy = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: false,
            persistedDecision: .legacy,
            hadCompletedOnboardingBeforeGate: false
        )
        XCTAssertEqual(asLegacy.cohort, .legacy)
        XCTAssertNil(asLegacy.decisionToPersist)
    }

    func testPreGateOnboardingWithoutMarkerMigratesToLegacy() {
        // Usuário pré-1.13 que completou o onboarding mas nunca iniciou o
        // trial local: não pode cair no portão como se fosse novo.
        let resolution = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: false,
            persistedDecision: nil,
            hadCompletedOnboardingBeforeGate: true
        )
        XCTAssertEqual(resolution.cohort, .legacy)
        XCTAssertEqual(resolution.decisionToPersist, .legacy)
    }

    func testFreshInstallIsNewAndPersistsDecision() {
        let resolution = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: false,
            persistedDecision: nil,
            hadCompletedOnboardingBeforeGate: false
        )
        XCTAssertEqual(resolution.cohort, .new)
        XCTAssertEqual(resolution.decisionToPersist, .new)
    }

    // MARK: - Refresh de entitlements resiliente

    func testActiveEntitlementsAlwaysApplyAndPersist() {
        let resolution = SubscriptionCohortPolicy.resolvedSubscriptionActive(
            activeProductCount: 1,
            encounteredUnverified: true,
            previousValue: false
        )
        XCTAssertTrue(resolution.isActive)
        XCTAssertTrue(resolution.shouldPersist)
    }

    func testInconclusiveEmptyEnumerationKeepsSubscriber() {
        // Falha transitória: nada verificado, mas havia assinatura antes.
        // Não rebaixar nem envenenar o cache.
        let resolution = SubscriptionCohortPolicy.resolvedSubscriptionActive(
            activeProductCount: 0,
            encounteredUnverified: true,
            previousValue: true
        )
        XCTAssertTrue(resolution.isActive)
        XCTAssertFalse(resolution.shouldPersist)
    }

    func testConclusiveEmptyEnumerationDowngrades() {
        let resolution = SubscriptionCohortPolicy.resolvedSubscriptionActive(
            activeProductCount: 0,
            encounteredUnverified: false,
            previousValue: true
        )
        XCTAssertFalse(resolution.isActive)
        XCTAssertTrue(resolution.shouldPersist)
    }

    func testEmptyEnumerationForNonSubscriberStaysInactive() {
        let resolution = SubscriptionCohortPolicy.resolvedSubscriptionActive(
            activeProductCount: 0,
            encounteredUnverified: true,
            previousValue: false
        )
        XCTAssertFalse(resolution.isActive)
        XCTAssertTrue(resolution.shouldPersist)
    }
}
