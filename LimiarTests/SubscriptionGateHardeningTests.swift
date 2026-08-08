import XCTest
@testable import Limiar

final class SubscriptionGateHardeningTests: XCTestCase {
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
