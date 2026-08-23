import Foundation
import Observation
import Security
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "limiar_premium_monthly"
    case yearly = "limiar_premium_annual_2026"

    var id: String { rawValue }

    var productID: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Mensal"
        case .yearly: "Anual"
        }
    }

    var sortOrder: Int {
        switch self {
        case .yearly: 0
        case .monthly: 1
        }
    }

    var badgeText: String? {
        switch self {
        case .monthly: nil
        case .yearly: "Melhor oferta"
        }
    }
}

enum SubscriptionPurchaseState: Equatable {
    case idle
    case loadingProducts
    case productsUnavailable
    case purchasing
    case purchased
    case restored
    case pending
    case cancelled
    case active
    case expired
    case failed(String)
}

enum SubscriptionPurchaseOrigin {
    case subscriptionGate
    case legacyPaywall
}

enum PurchaseFailureDiagnostics {
    static func code(for error: Error) -> LimiarAnalytics.PurchaseFailureCode {
        if error is SubscriptionVerificationError {
            return .unverifiedTransaction
        }

        if let storeKitError = error as? StoreKitError,
           case .userCancelled = storeKitError {
            return .userCancelled
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkError
        }

        let normalizedDomain = nsError.domain.lowercased()
        if nsError.domain == SKErrorDomain || normalizedDomain.contains("storekit") {
            if nsError.code == SKError.paymentCancelled.rawValue {
                return .userCancelled
            }
            return .storeKitError
        }

        return .unknownError
    }

    static func outcome(
        for code: LimiarAnalytics.PurchaseFailureCode
    ) -> LimiarAnalytics.PurchaseAttemptOutcome {
        switch code {
        case .userCancelled: .userCancelled
        case .unverifiedTransaction: .unverified
        default: .error
        }
    }

    static func isUserCancellation(
        _ code: LimiarAnalytics.PurchaseFailureCode
    ) -> Bool {
        code == .userCancelled
    }
}

enum SubscriptionCohort: String, Equatable {
    case legacy
    case new
}

enum IntroductoryOfferEligibility: Equatable {
    case unknown
    case eligible
    case ineligible

    var analyticsName: String {
        switch self {
        case .unknown: "unknown"
        case .eligible: "eligible"
        case .ineligible: "ineligible"
        }
    }
}

enum SubscriptionOfferPolicy {
    static func isSevenDayPeriod(
        unit: Product.SubscriptionPeriod.Unit,
        value: Int
    ) -> Bool {
        switch unit {
        case .day:
            value == 7
        case .week:
            value == 1
        case .month, .year:
            false
        @unknown default:
            false
        }
    }
}

enum SubscriptionWinbackPhase: String, Equatable {
    case trial
    case paid
}

enum SubscriptionWinbackPolicy {
    static func phase(
        cohort: SubscriptionCohort,
        hasActiveSubscription: Bool,
        autoRenewIsOff: Bool,
        isIntroductoryTrial: Bool
    ) -> SubscriptionWinbackPhase? {
        guard cohort == .new,
              hasActiveSubscription,
              autoRenewIsOff else {
            return nil
        }

        return isIntroductoryTrial ? .trial : .paid
    }

    /// Texto que completa "termina ..." no banner. A comunicação acompanha
    /// o dia civil, em vez de expor uma contagem regressiva por horas.
    static func remainingPeriodText(
        endsAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        guard let endsAt else { return "hoje" }

        let today = calendar.startOfDay(for: now)
        let endDay = calendar.startOfDay(for: endsAt)
        let days = calendar.dateComponents([.day], from: today, to: endDay).day ?? 0

        if days <= 0 { return "hoje" }
        if days == 1 { return "em 1 dia" }
        return "em \(days) dias"
    }
}

enum SubscriptionAccessState: Equatable {
    case trialNotStarted
    case trialActive
    case trialExpired
    case subscriptionRequired
    case subscribed

    var allowsPremiumFeatures: Bool {
        switch self {
        case .trialActive, .subscribed:
            return true
        case .trialNotStarted, .trialExpired, .subscriptionRequired:
            return false
        }
    }
}

enum SubscriptionCohortPolicy {
    static func cohort(hasLegacyTrialStart: Bool) -> SubscriptionCohort {
        hasLegacyTrialStart ? .legacy : .new
    }

    /// Decide a coorte na primeira execução desta versão e o que persistir.
    /// Um usuário pré-1.13 que completou o onboarding mas nunca tocou em
    /// "Começar minha travessia" não tem o marcador de trial no Keychain;
    /// sem esta migração ele seria tratado como novo e cairia no portão,
    /// quebrando a promessa "sem cartão" da tela antiga.
    static func initialCohort(
        hasLegacyTrialStart: Bool,
        persistedDecision: SubscriptionCohort?,
        hadCompletedOnboardingBeforeGate: Bool
    ) -> (cohort: SubscriptionCohort, decisionToPersist: SubscriptionCohort?) {
        if hasLegacyTrialStart {
            return (.legacy, persistedDecision == .legacy ? nil : .legacy)
        }
        if let persistedDecision {
            return (persistedDecision, nil)
        }
        if hadCompletedOnboardingBeforeGate {
            return (.legacy, .legacy)
        }
        return (.new, .new)
    }

    /// Aplica o resultado de uma enumeração de entitlements sem deixar uma
    /// falha transitória derrubar um assinante: só rebaixamos (e persistimos
    /// `false` no cache) quando a enumeração foi conclusiva — nenhuma
    /// transação chegou sem verificação.
    static func resolvedSubscriptionActive(
        activeProductCount: Int,
        encounteredUnverified: Bool,
        previousValue: Bool
    ) -> (isActive: Bool, shouldPersist: Bool) {
        if activeProductCount > 0 {
            return (true, true)
        }
        if encounteredUnverified && previousValue {
            return (previousValue, false)
        }
        return (false, true)
    }

    static func canStartLocalTrial(cohort: SubscriptionCohort) -> Bool {
        cohort == .legacy
    }

    static func accessState(
        cohort: SubscriptionCohort,
        hasActiveSubscription: Bool,
        trialStartedAt: Date?,
        now: Date,
        trialDuration: TimeInterval
    ) -> SubscriptionAccessState {
        if hasActiveSubscription {
            return .subscribed
        }

        guard cohort == .legacy else {
            return .subscriptionRequired
        }

        guard let trialStartedAt else {
            return .trialNotStarted
        }

        let trialEndsAt = trialStartedAt.addingTimeInterval(trialDuration)
        return now < trialEndsAt ? .trialActive : .trialExpired
    }

    static func hasPremiumAccess(
        cohort: SubscriptionCohort,
        hasActiveSubscription: Bool,
        accessState: SubscriptionAccessState
    ) -> Bool {
        cohort == .new ? hasActiveSubscription : accessState.allowsPremiumFeatures
    }

    static func isEssentialMode(
        cohort: SubscriptionCohort,
        hasActiveSubscription: Bool,
        accessState: SubscriptionAccessState
    ) -> Bool {
        cohort == .legacy && accessState == .trialExpired && !hasActiveSubscription
    }

    static func reviewAccessStartedAt(
        cohort: SubscriptionCohort,
        accessState: SubscriptionAccessState,
        hasActiveSubscription: Bool,
        trialStartedAt: Date?,
        activeEntitlementStartedAt: Date?
    ) -> Date? {
        switch cohort {
        case .legacy:
            guard accessState == .trialActive else { return nil }
            return trialStartedAt
        case .new:
            guard hasActiveSubscription else { return nil }
            return activeEntitlementStartedAt
        }
    }
}

enum ConversionFunnelPersistence {
    static let d6DismissedKey = "funnel.d6.dismissed"
    static let d7DismissedKey = "funnel.d7.dismissed"
    static let d8DismissedKey = "funnel.d8.dismissed"

    static func resetDismissals(in defaults: UserDefaults) {
        defaults.removeObject(forKey: d6DismissedKey)
        defaults.removeObject(forKey: d7DismissedKey)
        defaults.removeObject(forKey: d8DismissedKey)
    }
}

@MainActor
@Observable
final class SubscriptionManager {
    private enum Constants {
        static let entitlementCacheKey = "limiar.subscription.hasActiveSubscription"
        static let firebaseLifecycleMonitoringStartedAtKey = "limiar.analytics.subscriptionLifecycleStartedAt"
        static let cohortDecisionKey = "limiar.subscription.cohortDecision"
        static let reviewRequestDefaultsKeyPrefix = "limiar.review.requested"
        static let trialDuration: TimeInterval = 7 * 24 * 60 * 60
        static let reviewRequestMinimumTrialDuration: TimeInterval = 3 * 24 * 60 * 60
        static let reviewRequestMinimumCompletedReadings = 3
        static let reviewRequestMinimumActiveDays = 3
        static let productIDs = SubscriptionPlan.allCases
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.productID)
    }

    private(set) var products: [Product] = []
    private(set) var cohort: SubscriptionCohort
    private(set) var hasActiveSubscription = false
    private(set) var accessState = SubscriptionAccessState.trialNotStarted
    private(set) var trialStartedAt: Date?
    private(set) var activeEntitlementStartedAt: Date?
    private(set) var activeEntitlementIsIntroductoryTrial = false
    private(set) var autoRenewIsOff = false
    private(set) var currentPeriodEndsAt: Date?
    private(set) var activeProductIDs: Set<String> = []
    private(set) var introductoryOfferEligibility: [String: IntroductoryOfferEligibility] = [:]
    private(set) var state = SubscriptionPurchaseState.idle
    private(set) var message = ""
    var selectedPlan = SubscriptionPlan.monthly

    /// Marcador do Keychain de que este aparelho já teve assinatura ativa.
    /// Sobrevive à reinstalação e permite verificar antes de vender.
    private(set) var hadSubscriptionBefore = false
    /// True enquanto a primeira verificação de entitlements da sessão não
    /// terminou — o portão usa isso para não abrir direto como venda para
    /// quem pode ser assinante reinstalando o app.
    private(set) var isVerifyingInitialEntitlements = true
    /// Fica `true` quando a pessoa fecha a folha da App Store sem concluir,
    /// vindo do portão. Vive separado de `state` porque um refresh de
    /// entitlements sobrescreve `state` (.expired) e apagaria a segunda
    /// chance antes de ela aparecer.
    private(set) var showsGateRecovery = false

    @ObservationIgnored private var userDidSelectPlan = false
    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var productLoadingTask: Task<Void, Never>?
    @ObservationIgnored private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard

    init() {
        #if DEBUG
        Self.assertTrialEndDayClassification()
        #endif

        // Mantém o último entitlement verificado durante a restauração
        // assíncrona do StoreKit. A verificação atualizada continua sendo a
        // fonte de verdade e corrige este cache logo no start().
        // O marcador de trial do Keychain segue sendo a fronteira principal
        // entre coortes; usuários novos nunca recebem esse marcador. A
        // decisão de coorte é persistida na primeira execução para que um
        // legado que atualizou sem ter iniciado o trial não caia no portão.
        let legacyTrialStartedAt = TrialStartStore.load()
        let persistedDecision = SubscriptionCohort(
            rawValue: defaults.string(forKey: Constants.cohortDecisionKey)
                ?? SubscriptionKeychainFlags.legacyCohort.rawStoredValue
                ?? ""
        )
        let resolution = SubscriptionCohortPolicy.initialCohort(
            hasLegacyTrialStart: legacyTrialStartedAt != nil,
            persistedDecision: persistedDecision,
            hadCompletedOnboardingBeforeGate: ScreenTimePolicyStore().loadOnboardingState()
        )
        cohort = resolution.cohort
        if let decision = resolution.decisionToPersist {
            defaults.set(decision.rawValue, forKey: Constants.cohortDecisionKey)
            if decision == .legacy {
                SubscriptionKeychainFlags.legacyCohort.store(decision.rawValue)
            }
        }
        hasActiveSubscription = defaults.bool(forKey: Constants.entitlementCacheKey)
        hadSubscriptionBefore = SubscriptionKeychainFlags.wasSubscriber.rawStoredValue != nil
        trialStartedAt = legacyTrialStartedAt
        if defaults.object(forKey: Constants.firebaseLifecycleMonitoringStartedAtKey) == nil {
            defaults.set(Date(), forKey: Constants.firebaseLifecycleMonitoringStartedAtKey)
        }
        refreshAccessState()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var isBusy: Bool {
        state == .loadingProducts || state == .purchasing
    }

    var hasPremiumAccess: Bool {
        SubscriptionCohortPolicy.hasPremiumAccess(
            cohort: cohort,
            hasActiveSubscription: hasActiveSubscription,
            accessState: accessState
        )
    }

    var isEssentialMode: Bool {
        SubscriptionCohortPolicy.isEssentialMode(
            cohort: cohort,
            hasActiveSubscription: hasActiveSubscription,
            accessState: accessState
        )
    }

    var requiresSubscriptionGate: Bool {
        cohort == .new && !hasActiveSubscription
    }

    var analyticsAccess: LimiarAnalytics.Access? {
        if hasActiveSubscription {
            return activeEntitlementIsIntroductoryTrial ? .trial : .premium
        }
        if cohort == .legacy, accessState == .trialActive {
            return .trial
        }
        if isEssentialMode {
            return .essential
        }
        return nil
    }

    var canShowPaywall: Bool {
        guard cohort == .legacy,
              accessState == .trialExpired,
              !hasActiveSubscription,
              let postTrialPaywallStartsAt else {
            return false
        }

        return Date() >= postTrialPaywallStartsAt
    }

    var shouldShowPostTrialPaywall: Bool {
        canShowPaywall
    }

    var trialEndsAt: Date? {
        trialStartedAt?.addingTimeInterval(Constants.trialDuration)
    }

    var postTrialPaywallStartsAt: Date? {
        guard let trialEndsAt else { return nil }
        let calendar = Calendar.current
        let trialEndDay = calendar.startOfDay(for: trialEndsAt)
        return calendar.date(byAdding: .day, value: 1, to: trialEndDay)
    }

    var trialEndsTomorrow: Bool {
        guard accessState == .trialActive, let trialEndsAt else { return false }
        return Self.trialEndDate(
            trialEndsAt,
            isDaysAfter: 1,
            now: Date(),
            calendar: .current
        )
    }

    var trialEndsToday: Bool {
        guard accessState == .trialActive, let trialEndsAt else { return false }
        return Self.trialEndDate(
            trialEndsAt,
            isDaysAfter: 0,
            now: Date(),
            calendar: .current
        )
    }

    var shouldShowTrialConversion: Bool {
        cohort == .legacy && accessState == .trialActive && (trialEndsTomorrow || trialEndsToday)
    }

    private static func trialEndDate(
        _ trialEndsAt: Date,
        isDaysAfter dayOffset: Int,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard let expectedDay = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
            return false
        }
        return calendar.startOfDay(for: trialEndsAt) == expectedDay
    }

    #if DEBUG
    private static func assertTrialEndDayClassification() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_768_564_800) // 2026-01-16 12:00 UTC
        let todayEnd = calendar.date(byAdding: .hour, value: 6, to: now)!
        let tomorrowEnd = calendar.date(byAdding: .hour, value: 30, to: now)!
        let laterEnd = calendar.date(byAdding: .hour, value: 54, to: now)!

        assert(trialEndDate(todayEnd, isDaysAfter: 0, now: now, calendar: calendar))
        assert(!trialEndDate(todayEnd, isDaysAfter: 1, now: now, calendar: calendar))
        assert(trialEndDate(tomorrowEnd, isDaysAfter: 1, now: now, calendar: calendar))
        assert(!trialEndDate(laterEnd, isDaysAfter: 1, now: now, calendar: calendar))
    }
    #endif

    /// Registra uma única solicitação de avaliação por versão quando a pessoa
    /// já teve tempo de perceber valor no Limiar. O sistema ainda decide se o
    /// alerta nativo será exibido e aplica os próprios limites da App Store.
    func claimReviewRequestIfEligible(
        history: [ReadingHistoryItem],
        readingWasHealthy: Bool,
        now: Date = Date()
    ) -> Bool {
        guard let accessStartedAt = SubscriptionCohortPolicy.reviewAccessStartedAt(
            cohort: cohort,
            accessState: accessState,
            hasActiveSubscription: hasActiveSubscription,
            trialStartedAt: trialStartedAt,
            activeEntitlementStartedAt: activeEntitlementStartedAt
        ),
              now.timeIntervalSince(accessStartedAt) >= Constants.reviewRequestMinimumTrialDuration,
              readingWasHealthy,
              history.count >= Constants.reviewRequestMinimumCompletedReadings,
              completedReadingsSpanAtLeastThreeDays(history, calendar: .current),
              history.contains(where: { Calendar.current.isDate($0.completedAt, inSameDayAs: now) }) else {
            return false
        }

        let key = reviewRequestDefaultsKey
        guard defaults.object(forKey: key) == nil else { return false }

        defaults.set(now, forKey: key)
        LimiarEventLog(source: "app").log("review_request_requested", [
            "completedReadings": "\(history.count)",
            "activeDays": "\(activeReadingDayCount(history, calendar: .current))",
            "appVersion": appVersion
        ])
        LimiarAnalytics.trackReviewPromptRequested()
        return true
    }

    var monthlyMarketingPrice: String {
        displayPrice(for: .monthly)
    }

    var yearlyMarketingPrice: String {
        displayPrice(for: .yearly)
    }

    var marketingPricingLine: String {
        let yearly = product(for: .yearly)
        let monthly = product(for: .monthly)

        if yearly != nil, monthly != nil {
            return "Depois \(displayPrice(for: .yearly))/ano ou \(displayPrice(for: .monthly))/mês"
        }

        if yearly != nil {
            return "Depois \(displayPrice(for: .yearly))/ano"
        }

        if monthly != nil {
            return "Depois \(displayPrice(for: .monthly))/mês"
        }

        return "Preço confirmado pela App Store antes da assinatura"
    }

    var pricingDisclosureText: String {
        let prices = availablePlanPrices()

        if prices.count >= 2 {
            return "Escolha entre \(prices.joined(separator: " ou ")). A App Store confirma preço e renovação antes da assinatura."
        }

        if let price = prices.first {
            return "Plano disponível por \(price). A App Store confirma preço e renovação antes da assinatura."
        }

        if products.isEmpty {
            return "Carregando preços pela App Store. A App Store confirma preço e renovação antes da assinatura."
        }

        return "Os preços serão exibidos pela App Store assim que os planos estiverem disponíveis."
    }

    var canResetTrialForTesting: Bool {
        Self.isTestEnvironment
    }

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "unknown"
    }

    private var reviewRequestDefaultsKey: String {
        "\(Constants.reviewRequestDefaultsKeyPrefix).\(appVersion)"
    }

    private func completedReadingsSpanAtLeastThreeDays(
        _ history: [ReadingHistoryItem],
        calendar: Calendar
    ) -> Bool {
        activeReadingDayCount(history, calendar: calendar) >= Constants.reviewRequestMinimumActiveDays
    }

    private func activeReadingDayCount(
        _ history: [ReadingHistoryItem],
        calendar: Calendar
    ) -> Int {
        Set(history.map { calendar.startOfDay(for: $0.completedAt) }).count
    }

    var statusText: String {
        if !message.isEmpty { return message }

        switch state {
        case .idle:
            return ""
        case .loadingProducts:
            return "Carregando planos..."
        case .productsUnavailable:
            return "Os planos ainda não estão disponíveis. Verifique os produtos no App Store Connect."
        case .purchasing:
            return "Abrindo assinatura..."
        case .purchased:
            return "Assinatura ativada."
        case .restored:
            return "Compra restaurada."
        case .pending:
            return "A compra está pendente de aprovação."
        case .cancelled:
            return "Compra cancelada. Nada foi cobrado."
        case .active:
            return "Limiar Premium ativo."
        case .expired:
            return "Nenhuma assinatura ativa encontrada."
        case .failed(let reason):
            return reason
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        transactionUpdatesTask = listenForTransactions()

        Task {
            await refresh()
        }
    }

    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    /// Tenta carregar os produtos ao apresentar uma oferta. Diferente de
    /// `start()`, pode ser chamado novamente depois de uma falha de rede.
    func prepareProductsIfNeeded() async {
        guard products.isEmpty else { return }
        await loadProducts()
        if products.isEmpty {
            await loadProducts()
        }
    }

    func refreshAccessState(now: Date = Date()) {
        accessState = SubscriptionCohortPolicy.accessState(
            cohort: cohort,
            hasActiveSubscription: hasActiveSubscription,
            trialStartedAt: trialStartedAt,
            now: now,
            trialDuration: Constants.trialDuration
        )
    }

    func startFreeTrial() {
        guard SubscriptionCohortPolicy.canStartLocalTrial(cohort: cohort) else {
            refreshAccessState()
            return
        }

        guard !hasActiveSubscription else {
            refreshAccessState()
            return
        }

        if trialStartedAt == nil {
            let now = Date()
            ConversionFunnelPersistence.resetDismissals(in: defaults)
            trialStartedAt = now
            TrialStartStore.save(now)
            message = "Seu acesso inicial de 7 dias começou."
            MetaAppEvents.trackLocalTrialStarted()
        }

        refreshAccessState()
    }

    func resetFreeTrialForTesting() {
        guard Self.isTestEnvironment,
              SubscriptionCohortPolicy.canStartLocalTrial(cohort: cohort) else {
            return
        }

        let now = Date()
        ConversionFunnelPersistence.resetDismissals(in: defaults)
        trialStartedAt = now
        TrialStartStore.save(now)
        message = "Acesso inicial reiniciado para 7 dias neste aparelho."
        refreshAccessState(now: now)
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    func storeDisplayPrice(for plan: SubscriptionPlan) -> String {
        guard let product = product(for: plan) else {
            return products.isEmpty ? "Carregando oferta" : "Plano indisponível"
        }
        return product.displayPrice
    }

    func introductoryOfferEligibility(for plan: SubscriptionPlan) -> IntroductoryOfferEligibility {
        introductoryOfferEligibility[plan.productID] ?? .unknown
    }

    /// Preço mensal equivalente do plano anual ("sai por R$ 7,49/mês"),
    /// formatado na moeda da própria loja. Âncora de custo-benefício no
    /// portão quando o mensal vem primeiro na lista.
    func monthlyEquivalentDisplayPrice(for plan: SubscriptionPlan) -> String? {
        guard plan == .yearly, let product = product(for: plan) else { return nil }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle)
    }

    /// "Economize R$ 28,90": diferença entre 12 mensais e o anual, na moeda
    /// da loja. `nil` quando não há economia ou faltam produtos.
    func yearlySavingsDisplayPrice() -> String? {
        guard let yearly = product(for: .yearly),
              let monthly = product(for: .monthly) else { return nil }
        let savings = monthly.price * Decimal(12) - yearly.price
        guard savings > 0 else { return nil }
        return savings.formatted(yearly.priceFormatStyle)
    }

    /// "R$ 0,00" na moeda da loja, para a linha "a Apple pede sua
    /// confirmação · R$ 0,00 hoje".
    func zeroDisplayPrice() -> String {
        guard let product = product(for: selectedPlan) ?? products.first else {
            return "R$ 0,00"
        }
        return Decimal(0).formatted(product.priceFormatStyle)
    }

    func hasEligibleFreeTrial(for plan: SubscriptionPlan) -> Bool {
        hasConfirmedFreeTrial(for: plan) && introductoryOfferEligibility(for: plan) == .eligible
    }

    func displayPrice(for plan: SubscriptionPlan) -> String {
        guard let product = product(for: plan) else {
            return products.isEmpty ? "Carregando oferta" : "Plano indisponível"
        }

        // O StoreKit localiza corretamente o preço na App Store. Em builds de
        // desenvolvimento, porém, o simulador pode usar a storefront dos EUA.
        // Mantemos a comunicação do Limiar em reais nesses ambientes para que
        // o paywall não misture dólar com a oferta brasileira.
        if Self.isTestEnvironment, !product.displayPrice.contains("R$") {
            return fallbackBrazilianPrice(for: plan)
        }

        return product.displayPrice
    }

    func dailyEquivalentPrice(for plan: SubscriptionPlan) -> String? {
        guard plan == .yearly, let product = product(for: plan) else { return nil }

        if Self.isTestEnvironment, !product.displayPrice.contains("R$") {
            return "R$ 0,25"
        }

        // Arredonda o centavo para CIMA: a copy diz "menos de X por dia" e a
        // afirmação precisa continuar verdadeira após o arredondamento.
        var dailyPrice = Decimal()
        var rawDaily = product.price / Decimal(365)
        NSDecimalRound(&dailyPrice, &rawDaily, 2, .up)
        return dailyPrice.formatted(product.priceFormatStyle)
    }

    private func fallbackBrazilianPrice(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly:
            return "R$ 9,90"
        case .yearly:
            return "R$ 89,90"
        }
    }

    func hasConfirmedFreeTrial(for plan: SubscriptionPlan) -> Bool {
        guard let offer = product(for: plan)?.subscription?.introductoryOffer else { return false }
        return offer.paymentMode == .freeTrial
            && SubscriptionOfferPolicy.isSevenDayPeriod(
                unit: offer.period.unit,
                value: offer.period.value
            )
    }

    func trialText(for plan: SubscriptionPlan) -> String {
        guard let product = product(for: plan) else {
            return products.isEmpty ? "Carregando oferta" : "Plano indisponível"
        }

        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return ""
        }

        return "\(displayText(for: offer.period)) de acesso inicial"
    }

    func planDetailText(for plan: SubscriptionPlan) -> String {
        guard product(for: plan) != nil else {
            return products.isEmpty ? "Carregando oferta" : "Plano indisponível"
        }

        if hasConfirmedFreeTrial(for: plan) {
            return trialText(for: plan)
        }

        switch plan {
        case .monthly:
            return "Renovação mensal. Cancele quando quiser."
        case .yearly:
            return yearlySavingsText() ?? "Renovação anual. Cancele quando quiser."
        }
    }

    func renewalDisclosure(for plan: SubscriptionPlan) -> String {
        guard product(for: plan) != nil else {
            return "Preço e renovação serão confirmados pela App Store antes da assinatura."
        }

        let price = displayPrice(for: plan)
        let period = plan == .yearly ? "por ano" : "por mês"
        if hasConfirmedFreeTrial(for: plan) {
            return "\(trialText(for: plan)). Depois, \(price) \(period). Cancele quando quiser."
        }
        return "Depois, \(price) \(period). Cancele quando quiser."
    }

    func primaryButtonTitle(for plan: SubscriptionPlan) -> String {
        guard product(for: plan) != nil else {
            return products.isEmpty ? "Carregando planos" : "Plano indisponível"
        }
        return "Assinar por \(displayPrice(for: plan))"
    }

    private func availablePlanPrices() -> [String] {
        SubscriptionPlan.allCases
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { plan in
                guard product(for: plan) != nil else { return nil }
                return displayPrice(for: plan)
            }
    }

    private func yearlySavingsText() -> String? {
        guard let yearly = product(for: .yearly),
              let monthly = product(for: .monthly) else {
            return nil
        }

        let monthlyEquivalent = yearly.price / Decimal(12)
        let yearlyCostViaMonthly = monthly.price * Decimal(12)
        let savings = yearlyCostViaMonthly - yearly.price

        guard savings > 0 else {
            return "Renovação anual. Cancele quando quiser."
        }

        let monthlyEquivalentText = monthlyEquivalent.formatted(yearly.priceFormatStyle)
        let savingsText = savings.formatted(yearly.priceFormatStyle)
        return "Equivale a \(monthlyEquivalentText)/mês. Economize \(savingsText) por ano."
    }

    func canPurchase(_ plan: SubscriptionPlan) -> Bool {
        product(for: plan) != nil && !isBusy
    }

    func purchaseSelectedPlan(
        origin: SubscriptionPurchaseOrigin = .legacyPaywall,
        legacyPaywallOrigin: LimiarAnalytics.PaywallOrigin? = nil
    ) async {
        await purchase(
            selectedPlan,
            origin: origin,
            legacyPaywallOrigin: legacyPaywallOrigin
        )
    }

    func purchase(
        _ plan: SubscriptionPlan,
        origin: SubscriptionPurchaseOrigin = .legacyPaywall,
        legacyPaywallOrigin: LimiarAnalytics.PaywallOrigin? = nil
    ) async {
        if products.isEmpty {
            await loadProducts()
        }

        let analyticsOrigin = checkoutAnalyticsOrigin(
            purchaseOrigin: origin,
            legacyPaywallOrigin: legacyPaywallOrigin
        )
        let offerEligibility = introductoryOfferEligibility(for: plan)

        guard let product = product(for: plan) else {
            LimiarAnalytics.trackPurchaseAttemptResult(
                plan: plan,
                outcome: .productUnavailable,
                origin: analyticsOrigin,
                offerEligibility: offerEligibility,
                errorCode: .productUnavailable
            )
            LimiarAnalytics.trackPurchaseFailed(
                plan: plan,
                reason: .error,
                errorCode: .productUnavailable,
                origin: analyticsOrigin,
                offerEligibility: offerEligibility
            )
            state = .productsUnavailable
            message = "Não encontramos este plano no StoreKit. Confirme o produto \(plan.productID) no App Store Connect."
            return
        }

        MetaAppEvents.trackCheckoutStarted()
        LimiarAnalytics.trackGatePurchaseStarted(
            plan,
            origin: analyticsOrigin,
            offerEligibility: offerEligibility
        )
        showsGateRecovery = false
        state = .purchasing
        message = ""

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                LimiarAnalytics.trackPurchaseAttemptResult(
                    plan: plan,
                    outcome: .success,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                trackFirebasePurchaseLifecycle(
                    for: transaction,
                    origin: analyticsOrigin
                )
                await transaction.finish()
                await refreshEntitlements()
                state = hasActiveSubscription ? .purchased : .expired
                message = hasActiveSubscription ? "Assinatura concluída. Limiar Premium ativo." : "A compra terminou, mas a assinatura ainda não apareceu como ativa."
                if hasActiveSubscription {
                    // Conversão do portão medida diretamente, sem depender de
                    // inferência por gate_purchase_started.
                    LimiarAnalytics.trackGatePurchaseCompleted(
                        plan,
                        origin: analyticsOrigin,
                        offerEligibility: offerEligibility
                    )
                }
            case .pending:
                LimiarAnalytics.trackPurchaseAttemptResult(
                    plan: plan,
                    outcome: .pending,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                LimiarAnalytics.trackPurchasePending(
                    plan: plan,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                state = .pending
                message = "A compra ficou pendente. Quando a Apple aprovar, o Premium ficará ativo automaticamente."
            case .userCancelled:
                LimiarAnalytics.trackPurchaseAttemptResult(
                    plan: plan,
                    outcome: .userCancelled,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                LimiarAnalytics.trackPurchaseCancelled(
                    plan: plan,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                MetaAppEvents.trackCheckoutCancelled()
                if origin == .subscriptionGate {
                    // Segunda chance calma: a pessoa fechou a folha da Apple e
                    // precisa ouvir que nada foi cobrado antes de decidir de novo.
                    showsGateRecovery = true
                }
                state = .cancelled
                message = "Compra cancelada. Sua assinatura não foi ativada."
            @unknown default:
                LimiarAnalytics.trackPurchaseAttemptResult(
                    plan: plan,
                    outcome: .error,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility,
                    errorCode: .unknownPurchaseResult
                )
                LimiarAnalytics.trackPurchaseFailed(
                    plan: plan,
                    reason: .error,
                    errorCode: .unknownPurchaseResult,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                MetaAppEvents.trackCheckoutFailed()
                state = .failed("Não foi possível concluir a compra agora.")
                message = "Não foi possível concluir a compra agora."
            }
        } catch {
            let errorCode = PurchaseFailureDiagnostics.code(for: error)
            LimiarAnalytics.trackPurchaseAttemptResult(
                plan: plan,
                outcome: PurchaseFailureDiagnostics.outcome(for: errorCode),
                origin: analyticsOrigin,
                offerEligibility: offerEligibility,
                errorCode: errorCode
            )
            if PurchaseFailureDiagnostics.isUserCancellation(errorCode) {
                LimiarAnalytics.trackPurchaseCancelled(
                    plan: plan,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                MetaAppEvents.trackCheckoutCancelled()
                if origin == .subscriptionGate {
                    showsGateRecovery = true
                }
                state = .cancelled
                message = "Compra cancelada. Sua assinatura não foi ativada."
            } else {
                LimiarAnalytics.trackPurchaseFailed(
                    plan: plan,
                    reason: .error,
                    errorCode: errorCode,
                    origin: analyticsOrigin,
                    offerEligibility: offerEligibility
                )
                MetaAppEvents.trackCheckoutFailed()
                state = .failed(error.localizedDescription)
                message = "Não foi possível concluir a compra: \(error.localizedDescription)"
            }
        }
    }

    func restorePurchases(
        origin: SubscriptionPurchaseOrigin = .legacyPaywall
    ) async {
        state = .loadingProducts
        message = "Buscando compras anteriores..."

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = hasActiveSubscription ? .restored : .expired
            message = hasActiveSubscription ? "Assinatura restaurada." : "Nenhuma assinatura ativa foi encontrada."
            if hasActiveSubscription, origin == .subscriptionGate {
                LimiarAnalytics.trackRestoreSucceeded()
            }
        } catch {
            if origin == .subscriptionGate {
                LimiarAnalytics.trackRestoreFailed()
            }
            state = .failed(error.localizedDescription)
            message = "Não foi possível restaurar agora: \(error.localizedDescription)"
        }
    }

    private func loadProducts() async {
        guard products.isEmpty else {
            await refreshIntroductoryOfferEligibility()
            return
        }

        if let productLoadingTask {
            await productLoadingTask.value
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performProductLoad()
        }
        productLoadingTask = task
        await task.value
        productLoadingTask = nil
    }

    private func performProductLoad() async {

        state = .loadingProducts
        message = ""

        do {
            let loadedProducts = try await Product.products(for: Constants.productIDs)
            products = loadedProducts.sorted { lhs, rhs in
                let lhsIndex = Constants.productIDs.firstIndex(of: lhs.id) ?? 0
                let rhsIndex = Constants.productIDs.firstIndex(of: rhs.id) ?? 0
                return lhsIndex < rhsIndex
            }
            if product(for: selectedPlan) == nil {
                // O plano escolhido não existe na loja: cair para o que houver.
                if product(for: .yearly) != nil {
                    selectedPlan = .yearly
                } else if product(for: .monthly) != nil {
                    selectedPlan = .monthly
                }
            } else if !userDidSelectPlan, product(for: .monthly) != nil {
                selectedPlan = .monthly
            }
            state = products.isEmpty ? .productsUnavailable : .idle
            if products.isEmpty {
                message = "Os produtos de assinatura ainda não foram retornados pelo StoreKit."
            } else {
                await refreshIntroductoryOfferEligibility()
            }
        } catch {
            state = .failed(error.localizedDescription)
            message = "Não foi possível carregar os planos: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var activeIDs = Set<String>()
        var entitlementStartDates: [Date] = []
        var entitlementExpirationDates: [Date] = []
        var subscriptionGroupIDs = Set<String>()
        var hasIntroductoryTrialEntitlement = false
        var encounteredUnverified = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else {
                encounteredUnverified = true
                continue
            }
            guard Constants.productIDs.contains(transaction.productID) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate <= Date() {
                continue
            }
            activeIDs.insert(transaction.productID)
            entitlementStartDates.append(transaction.purchaseDate)
            if let expirationDate = transaction.expirationDate {
                entitlementExpirationDates.append(expirationDate)
            }
            if let subscriptionGroupID = transaction.subscriptionGroupID {
                subscriptionGroupIDs.insert(subscriptionGroupID)
            }
            if transactionStartsIntroductoryFreeTrial(transaction) {
                hasIntroductoryTrialEntitlement = true
            }
            trackPurchaseLifecycle(for: transaction)
            trackFirebasePurchaseLifecycleIfObservable(for: transaction)
        }

        let resolution = SubscriptionCohortPolicy.resolvedSubscriptionActive(
            activeProductCount: activeIDs.count,
            encounteredUnverified: encounteredUnverified,
            previousValue: hasActiveSubscription
        )

        if resolution.isActive || resolution.shouldPersist {
            activeProductIDs = activeIDs
            activeEntitlementStartedAt = entitlementStartDates.min()
            activeEntitlementIsIntroductoryTrial = hasIntroductoryTrialEntitlement
        }
        hasActiveSubscription = resolution.isActive
        if hasActiveSubscription, !activeIDs.isEmpty {
            currentPeriodEndsAt = entitlementExpirationDates.max()
            await refreshRenewalState(
                activeProductIDs: activeIDs,
                subscriptionGroupIDs: subscriptionGroupIDs
            )
        } else if resolution.shouldPersist {
            autoRenewIsOff = false
            currentPeriodEndsAt = nil
        }
        if resolution.shouldPersist {
            defaults.set(hasActiveSubscription, forKey: Constants.entitlementCacheKey)
        }
        if hasActiveSubscription, !hadSubscriptionBefore {
            hadSubscriptionBefore = true
            SubscriptionKeychainFlags.wasSubscriber.store("true")
        }
        isVerifyingInitialEntitlements = false
        if hasActiveSubscription {
            showsGateRecovery = false
        }
        refreshAccessState()

        // A promessa do portão ("avisamos no dia 5") é cumprida aqui: o
        // lembrete local segue o entitlement real, não o toque no botão.
        LimiarNotificationCoordinator.shared.syncTrialReminder(
            trialEndsAt: hasActiveSubscription && activeEntitlementIsIntroductoryTrial
                ? currentPeriodEndsAt
                : nil
        )

        // .pending (Ask to Buy) permanece visível até o listener de
        // transações resolver a compra; um refresh de rotina não pode
        // esconder esse aviso.
        if state != .purchasing && state != .loadingProducts && state != .pending {
            state = hasActiveSubscription ? .active : .expired
        }
    }

    /// Recuperação ao voltar ao primeiro plano: recarrega produtos se a
    /// primeira carga falhou (sem rede no fim do onboarding, por exemplo)
    /// e revalida entitlements. Sem isso o portão ficava inerte na sessão.
    func recoverIfNeeded() async {
        if products.isEmpty || introductoryOfferEligibility.isEmpty {
            await loadProducts()
        }
        await refreshEntitlements()
    }

    /// Registra que o plano atual foi uma escolha explícita da pessoa, para
    /// que o carregamento de produtos não a sobrescreva com o padrão anual.
#if DEBUG
    /// `-LimiarForceGateRecovery`: abre a tela "A porta continua aberta" sem
    /// precisar cancelar uma compra real (QA e capturas).
    func forceGateRecoveryForDebugging() {
        showsGateRecovery = true
    }
#endif

    /// "Ver todos os planos" na tela de recuperação: volta ao portão normal.
    func dismissGateRecovery() {
        showsGateRecovery = false
        if state == .cancelled {
            state = .idle
            message = ""
        }
    }

    func noteUserSelectedPlan() {
        userDidSelectPlan = true
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(transactionResult)
            trackFirebasePurchaseLifecycle(for: transaction, origin: .storeKitUpdate)
            await transaction.finish()
            await refreshEntitlements()
        } catch {
            state = .failed(error.localizedDescription)
            message = "A Apple não conseguiu verificar uma transação recente."
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionVerificationError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }

    /// Renewal info não faz parte de `Transaction.currentEntitlements`.
    /// Consultamos o status do grupo e só aplicamos dados quando tanto a
    /// transação quanto o renewal info vierem verificados pelo StoreKit.
    private func refreshRenewalState(
        activeProductIDs: Set<String>,
        subscriptionGroupIDs: Set<String>
    ) async {
        var groupIDs = subscriptionGroupIDs
        if groupIDs.isEmpty {
            groupIDs.formUnion(
                products.compactMap { product in
                    guard activeProductIDs.contains(product.id) else { return nil }
                    return product.subscription?.subscriptionGroupID
                }
            )
        }

        guard !groupIDs.isEmpty else { return }

        var foundVerifiedActiveStatus = false
        var encounteredUnverified = false
        var latestExpirationDate: Date?
        var willAutoRenew = true

        do {
            for groupID in groupIDs {
                let statuses = try await Product.SubscriptionInfo.status(for: groupID)
                for status in statuses {
                    guard let transaction = try? checkVerified(status.transaction),
                          let renewalInfo = try? checkVerified(status.renewalInfo) else {
                        encounteredUnverified = true
                        continue
                    }
                    guard activeProductIDs.contains(transaction.productID),
                          transaction.revocationDate == nil,
                          let expirationDate = transaction.expirationDate,
                          expirationDate > Date() else {
                        continue
                    }

                    if latestExpirationDate == nil || expirationDate > latestExpirationDate! {
                        latestExpirationDate = expirationDate
                        willAutoRenew = renewalInfo.willAutoRenew
                    }
                    foundVerifiedActiveStatus = true
                }
            }
        } catch {
            // Uma falha transitória não pode sobrescrever um estado de
            // renovação que já havia sido verificado nesta instalação.
            return
        }

        guard foundVerifiedActiveStatus else {
            if !encounteredUnverified {
                autoRenewIsOff = false
            }
            return
        }

        autoRenewIsOff = !willAutoRenew
        if let latestExpirationDate {
            currentPeriodEndsAt = latestExpirationDate
        }
    }

    private func refreshIntroductoryOfferEligibility() async {
        var eligibility: [String: IntroductoryOfferEligibility] = [:]

        for plan in SubscriptionPlan.allCases {
            guard let subscription = product(for: plan)?.subscription,
                  subscription.introductoryOffer?.paymentMode == .freeTrial else {
                eligibility[plan.productID] = .ineligible
                continue
            }

            eligibility[plan.productID] = await subscription.isEligibleForIntroOffer
                ? .eligible
                : .ineligible
        }

        introductoryOfferEligibility = eligibility
    }

    private func trackPurchaseLifecycle(for transaction: Transaction) {
        if transactionStartsIntroductoryFreeTrial(transaction) {
            MetaAppEvents.trackStoreKitTrialStarted()
        } else {
            MetaAppEvents.trackSubscriptionActivated(
                originalTransactionID: transaction.originalID
            )
        }
    }

    private func trackFirebasePurchaseLifecycle(
        for transaction: Transaction,
        origin: LimiarAnalytics.CheckoutOrigin
    ) {
        guard let plan = SubscriptionPlan(rawValue: transaction.productID) else { return }

        if transactionStartsIntroductoryFreeTrial(transaction) {
            LimiarAnalytics.trackTrialStarted(
                plan: plan,
                originalTransactionID: transaction.originalID,
                origin: origin
            )
        } else {
            LimiarAnalytics.trackSubscriptionActivated(
                plan: plan,
                originalTransactionID: transaction.originalID,
                origin: origin
            )
        }
    }

    /// Evita registrar assinaturas históricas como novas na primeira abertura
    /// com Firebase, mas captura uma conversão/renovação que ocorreu enquanto o
    /// app estava fechado depois que a telemetria já havia sido ativada.
    private func trackFirebasePurchaseLifecycleIfObservable(for transaction: Transaction) {
        guard let monitoringStartedAt = defaults.object(
            forKey: Constants.firebaseLifecycleMonitoringStartedAtKey
        ) as? Date,
              transaction.purchaseDate >= monitoringStartedAt else {
            return
        }
        trackFirebasePurchaseLifecycle(for: transaction, origin: .storeKitUpdate)
    }

    private func checkoutAnalyticsOrigin(
        purchaseOrigin: SubscriptionPurchaseOrigin,
        legacyPaywallOrigin: LimiarAnalytics.PaywallOrigin?
    ) -> LimiarAnalytics.CheckoutOrigin {
        if purchaseOrigin == .subscriptionGate {
            return .subscriptionGate
        }

        switch legacyPaywallOrigin {
        case .d6: return LimiarAnalytics.CheckoutOrigin.d6
        case .d7: return LimiarAnalytics.CheckoutOrigin.d7
        case .d8: return LimiarAnalytics.CheckoutOrigin.d8
        case .settings: return LimiarAnalytics.CheckoutOrigin.settings
        case .dashboard: return LimiarAnalytics.CheckoutOrigin.dashboard
        case nil: return LimiarAnalytics.CheckoutOrigin.dashboard
        }
    }

    private func transactionStartsIntroductoryFreeTrial(_ transaction: Transaction) -> Bool {
        if #available(iOS 17.2, *) {
            return transaction.offer?.type == .introductory
                && transaction.offer?.paymentMode == .freeTrial
        }

        // No iOS 17.0/17.1 o StoreKit expõe o tipo, mas não oferece o modo
        // tipado. Os produtos do Limiar têm somente oferta introdutória grátis.
        return transaction.offerType == .introductory
    }

    private func displayText(for period: Product.SubscriptionPeriod) -> String {
        let value = period.value
        switch period.unit {
        case .day:
            return value == 1 ? "1 dia" : "\(value) dias"
        case .week:
            return value == 1 ? "7 dias" : "\(value * 7) dias"
        case .month:
            return value == 1 ? "1 mês" : "\(value) meses"
        case .year:
            return value == 1 ? "1 ano" : "\(value) anos"
        @unknown default:
            return "período inicial"
        }
    }

    private static var isTestEnvironment: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}

enum SubscriptionVerificationError: LocalizedError {
    case unverifiedTransaction

    var errorDescription: String? {
        "A Apple não conseguiu verificar esta transação. Tente novamente em instantes."
    }
}

/// Marcadores simples no Keychain que sobrevivem à reinstalação. Nenhum deles
/// concede acesso por si só — apenas orientam classificação de coorte e a
/// ordem de verificação no portão. O guard-rail continua valendo: usuários
/// novos jamais recebem o marcador de trial local.
enum SubscriptionKeychainFlags: String {
    case legacyCohort = "cohortDecision"
    case wasSubscriber = "wasSubscriber"

    private static let service = "com.romeucunha.Limiar.subscription"

    var rawStoredValue: String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    func store(_ value: String) {
        let data = value.data(using: .utf8) ?? Data()
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        guard updateStatus == errSecItemNotFound else { return }

        var item = baseQuery
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: rawValue
        ]
    }
}

private enum TrialStartStore {
    private static let service = "com.romeucunha.Limiar.subscription"
    private static let account = "trialStartedAt"

    static func load() -> Date? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let rawValue = String(data: data, encoding: .utf8),
              let interval = TimeInterval(rawValue) else {
            return nil
        }

        return Date(timeIntervalSince1970: interval)
    }

    static func save(_ date: Date) {
        let data = String(date.timeIntervalSince1970).data(using: .utf8) ?? Data()
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        guard updateStatus == errSecItemNotFound else { return }

        var item = baseQuery
        item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
