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

enum SubscriptionAccessState: Equatable {
    case trialNotStarted
    case trialActive
    case trialExpired
    case subscribed

    var allowsPremiumFeatures: Bool {
        switch self {
        case .trialActive, .subscribed:
            return true
        case .trialNotStarted, .trialExpired:
            return false
        }
    }
}

@MainActor
@Observable
final class SubscriptionManager {
    private enum Constants {
        static let entitlementCacheKey = "limiar.subscription.hasActiveSubscription"
        static let trialStartDefaultsKey = "limiar.subscription.trialStartedAt"
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
    private(set) var hasActiveSubscription = false
    private(set) var accessState = SubscriptionAccessState.trialNotStarted
    private(set) var trialStartedAt: Date?
    private(set) var activeProductIDs: Set<String> = []
    private(set) var state = SubscriptionPurchaseState.idle
    private(set) var message = ""
    var selectedPlan = SubscriptionPlan.yearly

    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard

    init() {
        // Mantém o último entitlement verificado durante a restauração
        // assíncrona do StoreKit. A verificação atualizada continua sendo a
        // fonte de verdade e corrige este cache logo no start().
        hasActiveSubscription = defaults.bool(forKey: Constants.entitlementCacheKey)
        trialStartedAt = TrialStartStore.load() ?? defaults.object(forKey: Constants.trialStartDefaultsKey) as? Date
        refreshAccessState()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    var isBusy: Bool {
        state == .loadingProducts || state == .purchasing
    }

    var hasPremiumAccess: Bool {
        accessState.allowsPremiumFeatures
    }

    var isEssentialMode: Bool {
        accessState == .trialExpired && !hasActiveSubscription
    }

    var canShowPaywall: Bool {
        guard accessState == .trialExpired,
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

    var trialDaysRemaining: Int? {
        guard accessState == .trialActive, let trialEndsAt else { return nil }
        let remaining = trialEndsAt.timeIntervalSince(Date())
        guard remaining > 0 else { return 0 }
        return max(1, Int(ceil(remaining / 86_400)))
    }

    var shouldShowTrialConversion: Bool {
        accessState == .trialActive && trialDaysRemaining == 1
    }

    /// Registra uma única solicitação de avaliação por versão quando a pessoa
    /// já teve tempo de perceber valor no Limiar. O sistema ainda decide se o
    /// alerta nativo será exibido e aplica os próprios limites da App Store.
    func claimReviewRequestIfEligible(
        history: [ReadingHistoryItem],
        readingWasHealthy: Bool,
        now: Date = Date()
    ) -> Bool {
        guard accessState == .trialActive,
              let trialStartedAt,
              now.timeIntervalSince(trialStartedAt) >= Constants.reviewRequestMinimumTrialDuration,
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
            return "Depois \(displayPrice(for: .yearly))/Ano ou \(displayPrice(for: .monthly))/Mês"
        }

        if yearly != nil {
            return "Depois \(displayPrice(for: .yearly))/Ano"
        }

        if monthly != nil {
            return "Depois \(displayPrice(for: .monthly))/Mês"
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

    var trialRemainingText: String {
        guard let days = trialDaysRemaining else { return "" }
        return days == 1 ? "1 dia restante" : "\(days) dias restantes"
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
            return "Compra cancelada. Você pode continuar sem assinatura ativa."
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

    func refreshAccessState(now: Date = Date()) {
        if hasActiveSubscription {
            accessState = .subscribed
            return
        }

        guard let trialStartedAt else {
            accessState = .trialNotStarted
            return
        }

        let trialEndsAt = trialStartedAt.addingTimeInterval(Constants.trialDuration)
        accessState = now < trialEndsAt ? .trialActive : .trialExpired
    }

    func startFreeTrial() {
        guard !hasActiveSubscription else {
            refreshAccessState()
            return
        }

        if trialStartedAt == nil {
            let now = Date()
            trialStartedAt = now
            TrialStartStore.save(now)
            defaults.set(now, forKey: Constants.trialStartDefaultsKey)
            message = "Seu acesso inicial de 7 dias começou."
        }

        refreshAccessState()
    }

    func resetFreeTrialForTesting() {
        guard Self.isTestEnvironment else { return }

        let now = Date()
        trialStartedAt = now
        TrialStartStore.save(now)
        defaults.set(now, forKey: Constants.trialStartDefaultsKey)
        message = "Acesso inicial reiniciado para 7 dias neste aparelho."
        refreshAccessState(now: now)
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.productID }
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

    func monthlyEquivalentPrice(for plan: SubscriptionPlan) -> String? {
        guard plan == .yearly, let product = product(for: plan) else { return nil }

        if Self.isTestEnvironment, !product.displayPrice.contains("R$") {
            return "R$ 7,49"
        }

        return (product.price / Decimal(12)).formatted(product.priceFormatStyle)
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
        if hasConfirmedFreeTrial(for: plan) {
            return "\(trialText(for: plan)). Depois \(price). Cancele quando quiser."
        }
        return "Depois \(price). Cancele quando quiser."
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

    func purchaseSelectedPlan() async {
        await purchase(selectedPlan)
    }

    func purchase(_ plan: SubscriptionPlan) async {
        if products.isEmpty {
            await loadProducts()
        }

        guard let product = product(for: plan) else {
            state = .productsUnavailable
            message = "Não encontramos este plano no StoreKit. Confirme o produto \(plan.productID) no App Store Connect."
            return
        }

        state = .purchasing
        message = ""

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                state = hasActiveSubscription ? .purchased : .expired
                message = hasActiveSubscription ? "Assinatura concluída. Limiar Premium ativo." : "A compra terminou, mas a assinatura ainda não apareceu como ativa."
            case .pending:
                state = .pending
                message = "A compra ficou pendente. Quando a Apple aprovar, o Premium ficará ativo automaticamente."
            case .userCancelled:
                state = .cancelled
                message = "Compra cancelada. Sua assinatura não foi ativada."
            @unknown default:
                state = .failed("Não foi possível concluir a compra agora.")
                message = "Não foi possível concluir a compra agora."
            }
        } catch {
            state = .failed(error.localizedDescription)
            message = "Não foi possível concluir a compra: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        state = .loadingProducts
        message = "Buscando compras anteriores..."

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = hasActiveSubscription ? .restored : .expired
            message = hasActiveSubscription ? "Assinatura restaurada." : "Nenhuma assinatura ativa foi encontrada."
        } catch {
            state = .failed(error.localizedDescription)
            message = "Não foi possível restaurar agora: \(error.localizedDescription)"
        }
    }

    private func loadProducts() async {
        guard products.isEmpty else { return }

        state = .loadingProducts
        message = ""

        do {
            let loadedProducts = try await Product.products(for: Constants.productIDs)
            products = loadedProducts.sorted { lhs, rhs in
                let lhsIndex = Constants.productIDs.firstIndex(of: lhs.id) ?? 0
                let rhsIndex = Constants.productIDs.firstIndex(of: rhs.id) ?? 0
                return lhsIndex < rhsIndex
            }
            if product(for: .yearly) != nil {
                selectedPlan = .yearly
            } else if product(for: selectedPlan) == nil, product(for: .monthly) != nil {
                selectedPlan = .monthly
            }
            state = products.isEmpty ? .productsUnavailable : .idle
            if products.isEmpty {
                message = "Os produtos de assinatura ainda não foram retornados pelo StoreKit."
            }
        } catch {
            state = .failed(error.localizedDescription)
            message = "Não foi possível carregar os planos: \(error.localizedDescription)"
        }
    }

    private func refreshEntitlements() async {
        var activeIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard Constants.productIDs.contains(transaction.productID) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate <= Date() {
                continue
            }
            activeIDs.insert(transaction.productID)
        }

        activeProductIDs = activeIDs
        hasActiveSubscription = !activeIDs.isEmpty
        defaults.set(hasActiveSubscription, forKey: Constants.entitlementCacheKey)
        refreshAccessState()

        if state != .purchasing && state != .loadingProducts {
            state = hasActiveSubscription ? .active : .expired
        }
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
            throw StoreKitError.notAvailableInStorefront
        case .verified(let safe):
            return safe
        }
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
