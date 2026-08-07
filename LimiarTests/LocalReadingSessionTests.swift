import XCTest
import StoreKit
import SwiftUI
@testable import Limiar

final class LocalReadingSessionTests: XCTestCase {
    func testOnboardingNavigationDirectionMirrorsPageEdges() {
        XCTAssertEqual(OnboardingNavigationDirection.forward.insertionEdge, .trailing)
        XCTAssertEqual(OnboardingNavigationDirection.forward.removalEdge, .leading)
        XCTAssertEqual(OnboardingNavigationDirection.backward.insertionEdge, .leading)
        XCTAssertEqual(OnboardingNavigationDirection.backward.removalEdge, .trailing)
        XCTAssertEqual(OnboardingPageMotion.duration, 0.32, accuracy: 0.001)
    }

    func testStarterProfileUsesShortExplanationDepth() {
        XCTAssertEqual(UserFaithProfile.starter.explanationDepth, .short)
    }

    func testStarterProfileSelectsTheFirstEightStandaloneThemes() {
        XCTAssertEqual(
            UserFaithProfile.starter.favoriteThemes,
            Array(SpiritualTheme.standaloneOptions.prefix(8))
        )
    }

    func testCompletionScreenUsesTurnSpecificIcons() {
        XCTAssertEqual(completionPresentation(turn: .morning).iconName, "sunrise.fill")
        XCTAssertEqual(completionPresentation(turn: .afternoon).iconName, "sun.max.fill")
        XCTAssertEqual(completionPresentation(turn: .evening).iconName, "moon.stars.fill")
    }

    func testCompletionScreenReferencesTomorrowForMorningAfternoonAndEvening() throws {
        let cases: [(PauseCycleTurn, String)] = [
            (.morning, "amanhã às 5h"),
            (.afternoon, "amanhã às 13h"),
            (.evening, "amanhã às 19h")
        ]

        for (turn, expected) in cases {
            let presentation = completionPresentation(turn: turn, dayOffset: 1)
            XCTAssertEqual(presentation.nextCycleReference, expected)
        }
    }

    func testCompletionScreenReferencesTodayForOvernightEveningCycle() {
        XCTAssertEqual(
            completionPresentation(turn: .evening, dayOffset: 0).nextCycleReference,
            "hoje às 19h"
        )
    }

    func testLocalFactoryRespectsRequestedCountAndKeepsOnlyCanonicalReading() {
        let passages = (1...3).map { index in
            ScripturePassage(
                id: "passage-\(index)",
                tradition: .catholic,
                title: "Trecho \(index)",
                reference: "Salmo \(index)",
                text: "Texto canônico \(index)",
                estimatedMinutes: 5,
                theme: .hope,
                section: .psalms,
                book: .psalms
            )
        }

        for count in 1...3 {
            let items = LocalReadingSessionFactory.items(from: passages, itemCount: count)

            XCTAssertEqual(items.count, count)
            XCTAssertEqual(items.map(\.passageID), passages.prefix(count).map { Optional($0.id) })
            XCTAssertTrue(items.allSatisfy { $0.homily.isEmpty })
            XCTAssertTrue(items.allSatisfy { $0.practicalConclusion.isEmpty })
            XCTAssertTrue(items.allSatisfy { !$0.hasExplanationContent })
        }
    }

    func testSnapshotPersistsLocalSourceAndFailureReason() throws {
        let snapshot = DailyReadingSessionSnapshot(
            dayKey: "2026-07-20",
            profileKey: "profile",
            items: [],
            reflection: emptyReflection,
            source: .local,
            failureReason: "url_error_-1009"
        )

        let decoded = try JSONDecoder().decode(
            DailyReadingSessionSnapshot.self,
            from: JSONEncoder().encode(snapshot)
        )

        XCTAssertEqual(decoded.source, .local)
        XCTAssertEqual(decoded.failureReason, "url_error_-1009")
    }

    func testLegacySnapshotDefaultsToRemoteSource() throws {
        let snapshot = DailyReadingSessionSnapshot(
            dayKey: "2026-07-20",
            profileKey: "profile",
            items: [],
            reflection: emptyReflection
        )
        let encoded = try JSONEncoder().encode(snapshot)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "source")
        object.removeValue(forKey: "failureReason")

        let decoded = try JSONDecoder().decode(
            DailyReadingSessionSnapshot.self,
            from: JSONSerialization.data(withJSONObject: object)
        )

        XCTAssertEqual(decoded.source, .remote)
        XCTAssertNil(decoded.failureReason)
    }

    func testUpgradeOnlyRunsBeforeTraversalAndCycleCompletion() {
        XCTAssertTrue(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .remote,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: true,
                hasCompletedCurrentCycle: false
            )
        )
        XCTAssertFalse(
            LocalSessionUpgradePolicy.shouldAttempt(
                source: .local,
                isReadingSessionActive: false,
                hasCompletedCurrentCycle: true
            )
        )
    }

    func testEveryTraditionRequiresThreeReadingStylesAndStartsWithThreeDefaults() {
        for tradition in FaithTradition.allCases {
            let config = tradition.readingConfig

            XCTAssertEqual(config.minSelected, 3, "\(tradition) deve exigir 3 estilos")
            XCTAssertEqual(config.defaultCategoryIDs.count, 3, "\(tradition) deve iniciar com 3 estilos")
        }
    }

    func testLegacyProfileWithTwoReadingStylesIsNotExpandedDuringNormalization() {
        var profile = UserFaithProfile.starter
        profile.selectedReadingCategoryIDs = ["evangelhos", "salmos"]

        profile.normalizeReadingPreferencesForTradition()

        XCTAssertEqual(profile.selectedReadingCategoryIDs, ["evangelhos", "salmos"])
        XCTAssertEqual(profile.selectedCategories.count, 2)
        XCTAssertFalse(profile.favoriteBooks.isEmpty)
        XCTAssertFalse(profile.favoriteBibleSections.isEmpty)
    }

    func testNarrationExplanationIsSplitIntoTrimmedParagraphs() {
        XCTAssertEqual(
            narrationExplanationSegments([
                "Primeiro parágrafo.\n\nSegundo parágrafo.",
                "  Aplicação final.  "
            ]),
            ["Primeiro parágrafo.", "Segundo parágrafo.", "Aplicação final."]
        )
    }

    func testNarrationExplanationIgnoresEmptyParagraphsAndNormalizesWindowsNewlines() {
        XCTAssertEqual(
            narrationExplanationSegments(["\r\n\r\nPrimeiro.\r\n\r\nSegundo.\r\n\r\n"]),
            ["Primeiro.", "Segundo."]
        )
    }

    func testFavoritePassagePreservesExplanationThroughCodableRoundTrip() throws {
        let favorite = FavoritePassageItem(
            id: UUID(),
            passageID: "salmo-23",
            passageTitle: "Salmo 23",
            reference: "Salmo 23, 1",
            text: "O Senhor é meu pastor.",
            homily: "A presença de Deus oferece direção.",
            practicalConclusion: "Confie o próximo passo a Ele.",
            savedAt: Date(timeIntervalSinceReferenceDate: 123)
        )

        let decoded = try JSONDecoder().decode(
            FavoritePassageItem.self,
            from: JSONEncoder().encode(favorite)
        )

        XCTAssertEqual(decoded, favorite)
        XCTAssertEqual(decoded.homily, favorite.homily)
        XCTAssertEqual(decoded.practicalConclusion, favorite.practicalConclusion)
    }

    func testLegacyFavoritePassageDecodesWithoutExplanation() throws {
        let favorite = FavoritePassageItem(
            id: UUID(),
            passageID: "salmo-23",
            passageTitle: "Salmo 23",
            reference: "Salmo 23, 1",
            text: "O Senhor é meu pastor.",
            savedAt: Date(timeIntervalSinceReferenceDate: 123)
        )
        var legacyObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(favorite)) as? [String: Any]
        )
        legacyObject.removeValue(forKey: "homily")
        legacyObject.removeValue(forKey: "practicalConclusion")

        let decoded = try JSONDecoder().decode(
            FavoritePassageItem.self,
            from: JSONSerialization.data(withJSONObject: legacyObject)
        )

        XCTAssertNil(decoded.homily)
        XCTAssertNil(decoded.practicalConclusion)
        XCTAssertEqual(decoded.text, favorite.text)
    }

    func testSubscriptionCohortComesOnlyFromLegacyKeychainMarker() {
        XCTAssertEqual(SubscriptionCohortPolicy.cohort(hasLegacyTrialStart: true), .legacy)
        XCTAssertEqual(SubscriptionCohortPolicy.cohort(hasLegacyTrialStart: false), .new)
        XCTAssertTrue(SubscriptionCohortPolicy.canStartLocalTrial(cohort: .legacy))
        XCTAssertFalse(SubscriptionCohortPolicy.canStartLocalTrial(cohort: .new))
    }

    func testIntroductoryOfferPolicyAcceptsExactlySevenDays() {
        XCTAssertTrue(SubscriptionOfferPolicy.isSevenDayPeriod(unit: .week, value: 1))
        XCTAssertTrue(SubscriptionOfferPolicy.isSevenDayPeriod(unit: .day, value: 7))
        XCTAssertFalse(SubscriptionOfferPolicy.isSevenDayPeriod(unit: .day, value: 3))
        XCTAssertFalse(SubscriptionOfferPolicy.isSevenDayPeriod(unit: .week, value: 2))
        XCTAssertFalse(SubscriptionOfferPolicy.isSevenDayPeriod(unit: .month, value: 1))
    }

    func testNewCohortRequiresSubscriptionAndNeverEntersEssentialMode() {
        let state = SubscriptionCohortPolicy.accessState(
            cohort: .new,
            hasActiveSubscription: false,
            trialStartedAt: nil,
            now: Date(),
            trialDuration: 7 * 24 * 60 * 60
        )

        XCTAssertEqual(state, .subscriptionRequired)
        XCTAssertFalse(
            SubscriptionCohortPolicy.hasPremiumAccess(
                cohort: .new,
                hasActiveSubscription: false,
                accessState: state
            )
        )
        XCTAssertFalse(
            SubscriptionCohortPolicy.isEssentialMode(
                cohort: .new,
                hasActiveSubscription: false,
                accessState: state
            )
        )
    }

    func testNewCohortGetsPremiumOnlyFromActiveStoreKitEntitlement() {
        let state = SubscriptionCohortPolicy.accessState(
            cohort: .new,
            hasActiveSubscription: true,
            trialStartedAt: nil,
            now: Date(),
            trialDuration: 7 * 24 * 60 * 60
        )

        XCTAssertEqual(state, .subscribed)
        XCTAssertTrue(
            SubscriptionCohortPolicy.hasPremiumAccess(
                cohort: .new,
                hasActiveSubscription: true,
                accessState: state
            )
        )
        XCTAssertFalse(
            SubscriptionCohortPolicy.isEssentialMode(
                cohort: .new,
                hasActiveSubscription: true,
                accessState: state
            )
        )
    }

    func testLegacyCohortKeepsTrialAndEssentialBehavior() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let activeTrial = SubscriptionCohortPolicy.accessState(
            cohort: .legacy,
            hasActiveSubscription: false,
            trialStartedAt: now.addingTimeInterval(-24 * 60 * 60),
            now: now,
            trialDuration: 7 * 24 * 60 * 60
        )
        let expiredTrial = SubscriptionCohortPolicy.accessState(
            cohort: .legacy,
            hasActiveSubscription: false,
            trialStartedAt: now.addingTimeInterval(-8 * 24 * 60 * 60),
            now: now,
            trialDuration: 7 * 24 * 60 * 60
        )

        XCTAssertEqual(activeTrial, .trialActive)
        XCTAssertTrue(
            SubscriptionCohortPolicy.hasPremiumAccess(
                cohort: .legacy,
                hasActiveSubscription: false,
                accessState: activeTrial
            )
        )
        XCTAssertEqual(expiredTrial, .trialExpired)
        XCTAssertTrue(
            SubscriptionCohortPolicy.isEssentialMode(
                cohort: .legacy,
                hasActiveSubscription: false,
                accessState: expiredTrial
            )
        )
    }

    func testReviewEligibilityUsesStoreKitTransactionDateForNewCohort() {
        let transactionDate = Date(timeIntervalSinceReferenceDate: 500)

        XCTAssertEqual(
            SubscriptionCohortPolicy.reviewAccessStartedAt(
                cohort: .new,
                accessState: .subscribed,
                hasActiveSubscription: true,
                trialStartedAt: nil,
                activeEntitlementStartedAt: transactionDate
            ),
            transactionDate
        )
        XCTAssertNil(
            SubscriptionCohortPolicy.reviewAccessStartedAt(
                cohort: .new,
                accessState: .subscriptionRequired,
                hasActiveSubscription: false,
                trialStartedAt: nil,
                activeEntitlementStartedAt: transactionDate
            )
        )
    }

    func testReviewEligibilityKeepsLegacyTrialRule() {
        let trialDate = Date(timeIntervalSinceReferenceDate: 500)

        XCTAssertEqual(
            SubscriptionCohortPolicy.reviewAccessStartedAt(
                cohort: .legacy,
                accessState: .trialActive,
                hasActiveSubscription: false,
                trialStartedAt: trialDate,
                activeEntitlementStartedAt: nil
            ),
            trialDate
        )
        XCTAssertNil(
            SubscriptionCohortPolicy.reviewAccessStartedAt(
                cohort: .legacy,
                accessState: .subscribed,
                hasActiveSubscription: true,
                trialStartedAt: trialDate,
                activeEntitlementStartedAt: Date()
            )
        )
    }

    private var emptyReflection: AIReflection {
        AIReflection(
            summary: "",
            spiritualMeaning: "",
            practicalApplication: "",
            conclusion: "",
            meditationQuestion: ""
        )
    }

    private func completionPresentation(
        turn: PauseCycleTurn,
        dayOffset: Int = 1
    ) -> CompletionScreenPresentation {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 22, hour: 8))!
        let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: now)!
        let nextCycleStart = calendar.date(
            bySettingHour: turn.rawValue,
            minute: 0,
            second: 0,
            of: targetDay
        )!
        return CompletionScreenPresentation(
            turn: turn,
            now: now,
            nextCycleStart: nextCycleStart,
            calendar: calendar
        )
    }
}
