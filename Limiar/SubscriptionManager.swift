import Foundation
import Observation
import Security
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "limiar_premium_monthly"
    case yearly = "limiar_premium_yearly"

    var id: String { rawValue }

    var productID: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Mensal"
        case .yearly: "Anual"
        }
    }

    var fallbackPrice: String {
        switch self {
        case .monthly: "R$ 9,90/mês"
        case .yearly: "R$ 79,90/ano"
        }
    }

    var fallbackMonthlyEquivalent: String? {
        switch self {
        case .monthly: nil
        case .yearly: "equivale a R$ 6,66/mês"
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
        static let trialDuration: TimeInterval = 7 * 24 * 60 * 60
        static let productIDs = SubscriptionPlan.allCases.map(\.productID)
    }

    private(set) var products: [Product] = []
    private(set) var hasActiveSubscription = false
    private(set) var accessState = SubscriptionAccessState.trialNotStarted
    private(set) var trialStartedAt: Date?
    private(set) var activeProductIDs: Set<String> = []
    private(set) var state = SubscriptionPurchaseState.idle
    private(set) var message = ""
    var selectedPlan = SubscriptionPlan.monthly

    @ObservationIgnored private var transactionUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private let defaults = UserDefaults(suiteName: ScreenTimePolicyStore.appGroupIdentifier) ?? .standard

    init() {
        hasActiveSubscription = false
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

    var trialEndsAt: Date? {
        trialStartedAt?.addingTimeInterval(Constants.trialDuration)
    }

    var trialDaysRemaining: Int? {
        guard accessState == .trialActive, let trialEndsAt else { return nil }
        let remaining = trialEndsAt.timeIntervalSince(Date())
        guard remaining > 0 else { return 0 }
        return max(1, Int(ceil(remaining / 86_400)))
    }

    var shouldShowTrialConversion: Bool {
        guard accessState == .trialActive, let trialDaysRemaining else { return false }
        return trialDaysRemaining <= 2
    }

    var monthlyMarketingPrice: String {
        displayPrice(for: .monthly)
    }

    var trialRemainingText: String {
        guard let days = trialDaysRemaining else { return "" }
        return days == 1 ? "1 dia restante" : "\(days) dias restantes"
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
            message = "Seu teste gratuito de 7 dias começou."
        }

        refreshAccessState()
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    func displayPrice(for plan: SubscriptionPlan) -> String {
        guard let product = product(for: plan) else { return plan.fallbackPrice }

        switch plan {
        case .monthly:
            return "\(product.displayPrice)/mês"
        case .yearly:
            return "\(product.displayPrice)/ano"
        }
    }

    func monthlyEquivalentText(for plan: SubscriptionPlan) -> String? {
        guard plan == .yearly else { return nil }
        guard let product = product(for: .yearly) else { return plan.fallbackMonthlyEquivalent }

        let monthlyPrice = product.price / Decimal(12)
        return "equivale a \(monthlyPrice.formatted(product.priceFormatStyle))/mês"
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

        return "\(displayText(for: offer.period)) grátis"
    }

    func planDetailText(for plan: SubscriptionPlan) -> String {
        if let monthlyEquivalent = monthlyEquivalentText(for: plan) {
            return monthlyEquivalent
        }

        guard product(for: plan) != nil else {
            return products.isEmpty ? "Carregando oferta" : "Plano indisponível"
        }

        if hasConfirmedFreeTrial(for: plan) {
            return trialText(for: plan)
        }

        return "Renovação mensal. Cancele quando quiser."
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
        guard product(for: plan) != nil else { return "Carregando planos" }
        return "Assinar por \(displayPrice(for: plan))"
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
