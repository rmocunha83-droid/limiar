import XCTest
import StoreKit
import SwiftUI
@testable import Limiar

final class LocalReadingSessionTests: XCTestCase {
    func testReadingTextScalePolicyNormalizesAndMovesThroughSteps() {
        XCTAssertEqual(ReadingTextScalePolicy.steps, [90, 100, 110, 125, 140, 160])
        XCTAssertEqual(ReadingTextScalePolicy.normalized(107), 110)
        XCTAssertEqual(ReadingTextScalePolicy.normalized(105), 100)
        XCTAssertEqual(ReadingTextScalePolicy.incremented(100), 110)
        XCTAssertEqual(ReadingTextScalePolicy.incremented(160), 160)
        XCTAssertEqual(ReadingTextScalePolicy.decremented(125), 110)
        XCTAssertEqual(ReadingTextScalePolicy.decremented(90), 90)
    }

    func testReadingTextScaleCompositionRespectsLocalFloorAndAccessibility3Ceiling() {
        XCTAssertEqual(
            ReadingTextScalePolicy.composedScale(
                value: 90,
                systemScale: 1,
                accessibility3Scale: 2.4
            ),
            0.9,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ReadingTextScalePolicy.composedScale(
                value: 90,
                systemScale: 0.8,
                accessibility3Scale: 2.4
            ),
            0.9,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ReadingTextScalePolicy.composedScale(
                value: 125,
                systemScale: 1.2,
                accessibility3Scale: 2.4
            ),
            1.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ReadingTextScalePolicy.composedScale(
                value: 160,
                systemScale: 2,
                accessibility3Scale: 2.4
            ),
            2.4,
            accuracy: 0.001
        )
    }

    func testReadingTextScaleReaches160PercentWhenSystemTypeIsCappedAtLarge() {
        XCTAssertEqual(
            ReadingTextScalePolicy.composedScale(
                value: 160,
                systemScale: 1,
                accessibility3Scale: 2.4
            ),
            1.6,
            accuracy: 0.001
        )
    }

    func testReadingTextScaleStoreDefaultsNormalizesAndPersistsInInjectedSuite() throws {
        let suiteName = "LocalReadingSessionTests.ReadingTextScale.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let store = ReadingTextScaleStore(defaults: defaults)

        XCTAssertEqual(store.value, 100)

        store.save(125)
        XCTAssertEqual(defaults.integer(forKey: ReadingTextScaleStore.key), 125)
        XCTAssertEqual(store.value, 125)

        store.save(133)
        XCTAssertEqual(defaults.integer(forKey: ReadingTextScaleStore.key), 140)
        XCTAssertEqual(store.value, 140)
    }

    func testNarrationPreferencesNormalizeAndPersist() throws {
        XCTAssertEqual(NarrationPlaybackSpeedPolicy.steps, [0.8, 1.0, 1.2, 1.4])
        XCTAssertEqual(NarrationPlaybackSpeedPolicy.normalized(1.13), 1.2)
        XCTAssertEqual(NarrationPlaybackSpeedPolicy.label(for: 1), "1×")
        XCTAssertEqual(NarrationPlaybackSpeedPolicy.label(for: 1.4), "1.4×")

        let suiteName = "LocalReadingSessionTests.NarrationPreferences.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = NarrationPreferenceStore(defaults: defaults)

        XCTAssertEqual(store.speed, 1)
        XCTAssertEqual(store.voice, .antonio)
        store.saveSpeed(1.37)
        store.saveVoice(.francisca)
        XCTAssertEqual(store.speed, 1.4)
        XCTAssertEqual(store.voice, .francisca)
    }

    func testNarrationResumeCheckpointPersistsWithoutNarrationText() throws {
        let suiteName = "LocalReadingSessionTests.NarrationResume.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = NarrationResumeStore(defaults: defaults)
        let checkpoint = NarrationResumeCheckpoint(
            queueID: "hash-estavel",
            segmentIndex: 2,
            elapsedSeconds: 14.5
        )

        store.save(checkpoint)
        XCTAssertEqual(store.load(), checkpoint)
        store.clear()
        XCTAssertNil(store.load())
    }

    func testLegacyFavoriteWithoutRememberTodayStillDecodes() throws {
        let json = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "passageID": "salmo-27-1",
          "passageTitle": "Salmo 27",
          "reference": "Salmo 27, 1",
          "text": "O Senhor é minha luz.",
          "savedAt": 0
        }
        """.data(using: .utf8)!

        let favorite = try JSONDecoder().decode(FavoritePassageItem.self, from: json)
        XCTAssertNil(favorite.rememberToday)
        XCTAssertNil(favorite.theme)
    }

    func testSavedPassageRevisitPrioritizesSevenDayAnniversaryThenTheme() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 18, hour: 12))!
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let recent = calendar.date(byAdding: .day, value: -1, to: now)!
        let anniversary = favorite(id: "anniversary", theme: .hope, savedAt: sevenDaysAgo)
        let themed = favorite(id: "themed", theme: .family, savedAt: recent)

        let first = SavedPassageRevisitPolicy.suggestion(
            favorites: [themed, anniversary],
            currentThemes: [.family],
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(first?.favorite.passageID, "anniversary")
        XCTAssertEqual(first?.reason, .savedSevenDaysAgo)

        let second = SavedPassageRevisitPolicy.suggestion(
            favorites: [themed],
            currentThemes: [.family],
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(second?.favorite.passageID, "themed")
        XCTAssertEqual(second?.reason, .currentTheme)
    }

    func testSavedPassageRevisitUsesMondayPromptAndWeeklySummaryCountsCurrentWeek() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 8, day: 17, hour: 12))!
        let favorite = favorite(
            id: "old",
            theme: nil,
            savedAt: calendar.date(byAdding: .day, value: -20, to: monday)!
        )

        XCTAssertEqual(
            SavedPassageRevisitPolicy.suggestion(
                favorites: [favorite],
                currentThemes: [],
                now: monday,
                calendar: calendar
            )?.reason,
            .startOfWeek
        )

        let history = [
            ReadingHistoryItem(id: UUID(), passageID: "1", passageTitle: "A", reference: "A", completedAt: monday),
            ReadingHistoryItem(id: UUID(), passageID: "2", passageTitle: "B", reference: "B", completedAt: calendar.date(byAdding: .day, value: -8, to: monday)!)
        ]
        XCTAssertEqual(
            WeeklyPauseSummaryPolicy.completedCount(history: history, now: monday, calendar: calendar),
            1
        )
        XCTAssertEqual(
            WeeklyPauseSummaryPolicy.message(completedCount: 1),
            "Nesta semana, você transformou 1 impulso em pausa."
        )
        XCTAssertEqual(
            WeeklyPauseSummaryPolicy.message(completedCount: 5),
            "Nesta semana, você transformou 5 impulsos em pausas."
        )
    }

    func testOnboardingNavigationDirectionMirrorsPageEdges() {
        XCTAssertEqual(OnboardingNavigationDirection.forward.insertionEdge, .trailing)
        XCTAssertEqual(OnboardingNavigationDirection.forward.removalEdge, .leading)
        XCTAssertEqual(OnboardingNavigationDirection.backward.insertionEdge, .leading)
        XCTAssertEqual(OnboardingNavigationDirection.backward.removalEdge, .trailing)
        XCTAssertEqual(OnboardingPageMotion.duration, 0.32, accuracy: 0.001)
    }

    func testOnboardingFlowPlacesSocialProofBetweenPauseAndActivation() {
        XCTAssertEqual(
            OnboardingFlowStep.allCases,
            [.welcome, .tradition, .readings, .themes, .depth, .pauseTurn, .socialProof, .activation]
        )
        XCTAssertEqual(OnboardingFlowStep.socialProof.rawValue, 6)
        XCTAssertEqual(OnboardingFlowStep.activation.rawValue, 7)
        XCTAssertEqual(OnboardingFlowStep.final, .activation)
    }

    @MainActor
    func testTestimonialCatalogHasUniquePeopleAndExactOnboardingQuotes() {
        let testimonials = ConversionTestimonials.testimonials
        let people = testimonials.map { String($0.name.split(separator: ",", maxSplits: 1)[0]) }

        XCTAssertEqual(testimonials.count, 7)
        XCTAssertEqual(Set(people).count, people.count)
        XCTAssertEqual(
            testimonials.map(\.name),
            [
                "Juliana, Belo Horizonte/MG",
                "Rafael, Curitiba/PR",
                "Pedro, Brasília/DF",
                "Mariana, Recife/PE",
                "Beatriz, Porto Alegre/RS",
                "Lucas, Curitiba/PR",
                "Ana, Belo Horizonte/MG"
            ]
        )
        XCTAssertEqual(
            testimonials.map(\.quote),
            [
                "Não esperava tanto do aplicativo. Baixei sem grandes expectativas e me surpreendi. Prefiro prestar atenção no que estou fazendo e só depois olhar o celular. Com o Limiar consigo fazer essa pausa espiritual de forma natural. As reflexões personalizadas fazem toda a diferença. Já estou indicando para os amigos da igreja.",
                "Produto fantástico para quem quer colocar Deus antes das distrações. As leituras são curtas, claras e aparecem exatamente no momento em que eu mais preciso parar. Uso com os apps de rede social e WhatsApp. Em poucos segundos troco o impulso por uma Palavra. Estou muito satisfeito.",
                "Uma pausa pequena, mas que muda o resto do dia. Escolhi os apps que mais me distraem e agora, antes de abrir, tenho aqueles minutos de leitura e reflexão. É simples, bonito e direto. Sinto que estou colocando Deus no centro de novo, sem esforço. Cinco estrelas com sobra!",
                "O Limiar virou meu lembrete diário de prioridade. Eu queria ler mais a Bíblia, mas sempre acabava enrolando. Agora a pausa chega na hora certa, as leituras são adaptadas à minha tradição e ainda tem a opção de ouvir. Fácil de usar e realmente transforma o começo do dia. Estou muito grato por ter encontrado esse app.",
                "Honestamente eu não esperava tanto do aplicativo. Ele cria aquele segundo de consciência que a gente perde na rotina. A funcionalidade de áudio e a linguagem adaptada fazem toda a diferença. Fico com a mente bem mais leve durante o dia.",
                "Baixei pensando que seria só mais um bloqueador de apps, mas a proposta é incrível. Em vez de só bloquear, ele te convida a ler um texto curto com uma reflexão profunda. A narração em áudio é excelente para ouvir na correria da manhã. Recomendo demais!",
                "Simplesmente perfeito! Eu sempre abria o Instagram ou TikTok sem pensar e perdia horas. Com o Limiar, antes de qualquer distração aparece uma leitura rápida e uma reflexão. Mudou completamente minha rotina. Consigo começar o dia mais centrado e ainda consigo ler a Bíblia sem forçar."
            ]
        )
        XCTAssertEqual(
            ConversionTestimonials.onboardingTestimonials.map(\.name),
            ["Beatriz, Porto Alegre/RS", "Lucas, Curitiba/PR", "Ana, Belo Horizonte/MG"]
        )
        XCTAssertEqual(
            ConversionTestimonials.onboardingTestimonials.map(\.quote),
            [
                "Honestamente eu não esperava tanto do aplicativo. Ele cria aquele segundo de consciência que a gente perde na rotina. A funcionalidade de áudio e a linguagem adaptada fazem toda a diferença. Fico com a mente bem mais leve durante o dia.",
                "Baixei pensando que seria só mais um bloqueador de apps, mas a proposta é incrível. Em vez de só bloquear, ele te convida a ler um texto curto com uma reflexão profunda. A narração em áudio é excelente para ouvir na correria da manhã. Recomendo demais!",
                "Simplesmente perfeito! Eu sempre abria o Instagram ou TikTok sem pensar e perdia horas. Com o Limiar, antes de qualquer distração aparece uma leitura rápida e uma reflexão. Mudou completamente minha rotina. Consigo começar o dia mais centrado e ainda consigo ler a Bíblia sem forçar."
            ]
        )
        XCTAssertEqual(ConversionTestimonials.onboardingTestimonials.last?.id, testimonials.last?.id)
        XCTAssertEqual(ConversionTestimonials.onboardingTestimonials.last?.quote, testimonials.last?.quote)
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

    func testReadingNarrationUsesCanonicalPassageAndHomilyWithoutPracticalConclusion() {
        let item = SpiritualReadingItem(
            id: "salmo-23",
            reference: "Salmo 23, 1",
            text: "O Senhor é meu pastor.",
            homily: "Primeiro parágrafo da homilia.\n\nSegundo parágrafo da homilia.",
            practicalConclusion: "Conclusão prática que não deve ser narrada."
        )

        let segments = readingNarrationSegments(for: item)

        XCTAssertEqual(
            segments,
            [
                canonicalPassageNarrationText(reference: item.reference, text: item.text),
                "Primeiro parágrafo da homilia.",
                "Segundo parágrafo da homilia."
            ]
        )
        XCTAssertFalse(segments.contains(item.practicalConclusion))
    }

    func testSpiritualReadingCardPresentationUsesOnlyHomily() {
        let item = SpiritualReadingItem(
            id: "mateus-11",
            reference: "Mateus 11, 28",
            text: "Vinde a mim.",
            homily: "A homilia permanece visível no card.",
            practicalConclusion: "CONCLUSÃO SENTINELA QUE NÃO DEVE SER RENDERIZADA."
        )

        let renderedExplanation = SpiritualReadingCardPresentation.explanationText(for: item)

        XCTAssertEqual(renderedExplanation, item.homily)
        XCTAssertFalse(renderedExplanation.contains(item.practicalConclusion))
    }

    func testExplanationPanelAvailabilityDependsOnlyOnHomily() {
        let conclusionOnly = SpiritualReadingItem(
            id: "conclusion-only",
            reference: "Salmo 1, 1",
            text: "Texto.",
            homily: "  \n",
            practicalConclusion: "Conclusão preservada apenas para compatibilidade."
        )
        let homily = SpiritualReadingItem(
            id: "homily",
            reference: "Salmo 1, 2",
            text: "Texto.",
            homily: "Homilia visível.",
            practicalConclusion: ""
        )

        XCTAssertFalse(conclusionOnly.hasExplanationContent)
        XCTAssertTrue(homily.hasExplanationContent)
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

    private func favorite(
        id: String,
        theme: SpiritualTheme?,
        savedAt: Date
    ) -> FavoritePassageItem {
        FavoritePassageItem(
            id: UUID(),
            passageID: id,
            passageTitle: id,
            reference: id,
            text: "Texto",
            theme: theme,
            savedAt: savedAt
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
