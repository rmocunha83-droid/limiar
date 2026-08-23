import FirebaseAnalytics
import FirebaseCore
import Foundation

/// Taxonomia central de produto do Limiar.
///
/// Nunca inclua temas espirituais, referências ou textos de trechos,
/// explicações geradas, apps selecionados para bloqueio ou dados pessoais.
/// `reading_tradition` descreve apenas a preferência de catálogo de leitura e
/// existe para análise agregada de produto, nunca para publicidade direcionada.
@MainActor
enum LimiarAnalytics {
    enum OnboardingStep: String {
        case welcome
        case tradition
        case readings
        case themes
        case depth
        case screenTime = "screen_time"
        case socialProof = "social_proof"
        case activation
    }

    enum PaywallOrigin: String {
        case d6
        case d7
        case d8
        case settings
        case dashboard
    }

    enum Access: String {
        case trial
        case premium
        case essential
    }

    enum PurchaseFailureReason: String {
        case error
    }

    enum CheckoutOrigin: String {
        case subscriptionGate = "subscription_gate"
        case d6
        case d7
        case d8
        case settings
        case dashboard
        case storeKitUpdate = "storekit_update"
    }

    /// Código operacional de baixa cardinalidade. Não inclui mensagens de erro,
    /// identificadores de transação ou qualquer dado fornecido pela pessoa.
    enum PurchaseFailureCode: String {
        case productUnavailable = "product_unavailable"
        case userCancelled = "user_cancelled"
        case unknownPurchaseResult = "unknown_purchase_result"
        case unverifiedTransaction = "unverified_transaction"
        case networkError = "network_error"
        case storeKitError = "storekit_error"
        case unknownError = "unknown_error"
    }

    enum PurchaseAttemptOutcome: String, CaseIterable {
        case success
        case userCancelled = "user_cancelled"
        case pending
        case productUnavailable = "product_unavailable"
        case unverified
        case error
    }

    enum WinbackPhase: String {
        case trial
        case paid
    }

    enum ReadingTextScaleChangeMethod: String {
        case aa
        case pinch
    }

    private enum Keys {
        static let lastAccess = "limiar.analytics.lastAccess"
        static let traversalStartedPrefix = "limiar.analytics.traversalStarted"
        static let trialStartedPrefix = "limiar.analytics.trialStarted"
        static let subscriptionActivatedPrefix = "limiar.analytics.subscriptionActivated"
    }

    private static let defaults = UserDefaults(
        suiteName: ScreenTimePolicyStore.appGroupIdentifier
    ) ?? .standard
    private static var didTrackWinbackBannerThisSession = false

    private static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    static func trackOnboardingStepViewed(_ step: OnboardingStep, index: Int) {
        log("onboarding_step_viewed", parameters: [
            "step": step.rawValue,
            "index": index
        ])
    }

    static func trackTraditionSelected(_ tradition: FaithTradition) {
        log("tradition_selected", parameters: [
            "tradition": tradition.rawValue
        ])
    }

    static func trackOnboardingCompleted() {
        log("onboarding_completed")
    }

    static func trackATTPromptShown() {
        log("att_prompt_shown")
    }

    static func trackATTPromptResult(granted: Bool) {
        log("att_prompt_result", parameters: [
            "granted": granted ? 1 : 0
        ])
    }

    static func trackGateViewed(
        plan: SubscriptionPlan,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("gate_viewed", parameters: checkoutParameters(
            plan: plan,
            origin: .subscriptionGate,
            offerEligibility: offerEligibility
        ))
    }

    static func trackGatePlanSelected(
        _ plan: SubscriptionPlan,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("gate_plan_selected", parameters: checkoutParameters(
            plan: plan,
            origin: .subscriptionGate,
            offerEligibility: offerEligibility
        ))
    }

    static func trackGatePurchaseStarted(
        _ plan: SubscriptionPlan,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("gate_purchase_started", parameters: checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        ))
    }

    static func trackGatePurchaseCompleted(
        _ plan: SubscriptionPlan,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("gate_purchase_completed", parameters: checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        ))
    }

    /// Tela "A porta continua aberta", mostrada depois de fechar a folha da
    /// App Store. Permite medir quanto do abandono é recuperado.
    static func trackGateRecoveryViewed() {
        log("gate_recovery_viewed")
    }

    static func trackGateRecoveryRetry(_ plan: SubscriptionPlan) {
        log("gate_recovery_retry", parameters: [
            "plan": plan.analyticsName
        ])
    }

    static func trackGateRecoveryDismissed() {
        log("gate_recovery_dismissed")
    }

    static func trackTrialStarted(
        plan: SubscriptionPlan,
        originalTransactionID: UInt64,
        origin: CheckoutOrigin
    ) {
        logOnce(
            "trial_started",
            key: "\(Keys.trialStartedPrefix).\(originalTransactionID)",
            parameters: checkoutParameters(
                plan: plan,
                origin: origin,
                offerEligibility: .eligible
            )
        )
    }

    static func trackSubscriptionActivated(
        plan: SubscriptionPlan,
        originalTransactionID: UInt64,
        origin: CheckoutOrigin
    ) {
        logOnce(
            "subscription_activated",
            key: "\(Keys.subscriptionActivatedPrefix).\(originalTransactionID)",
            parameters: checkoutParameters(
                plan: plan,
                origin: origin,
                offerEligibility: .ineligible
            )
        )
    }

    static func trackPurchasePending(
        plan: SubscriptionPlan,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("purchase_pending", parameters: checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        ))
    }

    static func trackPurchaseCancelled(
        plan: SubscriptionPlan,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        log("purchase_cancelled", parameters: checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        ))
    }

    static func trackPurchaseFailed(
        plan: SubscriptionPlan,
        reason: PurchaseFailureReason,
        errorCode: PurchaseFailureCode,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) {
        var parameters = checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        )
        parameters["reason"] = reason.rawValue
        parameters["error_code"] = errorCode.rawValue
        log("purchase_failed", parameters: parameters)
    }

    /// Um único desfecho terminal por chamada a `purchase()`. Os eventos de
    /// funil e ciclo de vida existentes continuam separados para preservar as
    /// séries históricas, mas esta linha permite medir a saída da folha Apple
    /// sem inferir uma sequência a partir de contagens agregadas.
    static func trackPurchaseAttemptResult(
        plan: SubscriptionPlan,
        outcome: PurchaseAttemptOutcome,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility,
        errorCode: PurchaseFailureCode? = nil
    ) {
        var parameters = checkoutParameters(
            plan: plan,
            origin: origin,
            offerEligibility: offerEligibility
        )
        parameters["outcome"] = outcome.rawValue
        if let errorCode {
            parameters["error_code"] = errorCode.rawValue
        }
        log("purchase_attempt_result", parameters: parameters)
    }

    private static func checkoutParameters(
        plan: SubscriptionPlan,
        origin: CheckoutOrigin,
        offerEligibility: IntroductoryOfferEligibility
    ) -> [String: Any] {
        let paywallVersion: String
        switch origin {
        case .subscriptionGate:
            paywallVersion = "subscription_gate_v1"
        case .storeKitUpdate:
            paywallVersion = "storekit_observer"
        case .d6, .d7, .d8, .settings, .dashboard:
            paywallVersion = "legacy_paywall_v1"
        }

        return [
            "plan": plan.analyticsName,
            "origin": origin.rawValue,
            "offer_eligibility": offerEligibility.analyticsName,
            "paywall_version": paywallVersion
        ]
    }

    static func trackRestoreSucceeded() {
        log("restore_succeeded")
    }

    static func trackRestoreFailed() {
        log("restore_failed")
    }

    static func trackEssentialIntroViewed() {
        log("essential_intro_viewed")
    }

    static func trackTraversalStarted(turn: PauseCycleTurn, cycleKey: String) {
        pruneStaleTraversalMarkers()
        let localKey = "\(Keys.traversalStartedPrefix).\(cycleKey).\(turn.rawValue)"
        logOnce("travessia_started", key: localKey, parameters: [
            "turno": turn.analyticsName
        ])
    }

    /// As chaves de dedupe de travessia crescem ~1 por ciclo para sempre no
    /// plist do app group, que as extensões de Shield carregam inteiro.
    /// Mantemos apenas os últimos 90 dias — o dedupe só precisa do ciclo atual.
    static func pruneStaleTraversalMarkers(
        now: Date = Date(),
        maximumAgeInDays: Int = 90
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -maximumAgeInDays, to: now) else { return }

        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("\(Keys.traversalStartedPrefix).") {
            let components = key.dropFirst(Keys.traversalStartedPrefix.count + 1)
                .split(separator: ".", maxSplits: 1)
            guard let dayComponent = components.first,
                  let day = formatter.date(from: String(dayComponent)) else {
                continue
            }
            if day < cutoff {
                defaults.removeObject(forKey: key)
            }
        }
    }

    static func trackTraversalCompleted(
        turn: PauseCycleTurn,
        depth: ExplanationDepth
    ) {
        log("travessia_completed", parameters: [
            "turno": turn.analyticsName,
            "depth": depth.analyticsName
        ])
    }

    static func trackNarrationStarted(context: String = "travessia") {
        log("narration_started", parameters: [
            "context": context
        ])
    }

    static func trackNarrationFailed(reason: String, context: String = "travessia") {
        log("narration_failed", parameters: [
            "reason": reason,
            "context": context
        ])
    }

    static func trackPassageSaved() {
        log("passage_saved")
    }

    static func trackReviewPromptRequested() {
        log("review_prompt_requested")
    }

    static func trackWinbackBannerShown(phase: WinbackPhase) {
        guard !didTrackWinbackBannerThisSession else { return }
        guard log("winback_banner_shown", parameters: [
            "phase": phase.rawValue
        ]) else { return }
        didTrackWinbackBannerThisSession = true
    }

    static func trackWinbackBannerTapped(phase: WinbackPhase) {
        log("winback_banner_tapped", parameters: [
            "phase": phase.rawValue
        ])
    }

    static func trackReadingTextScaleChanged(
        value: Int,
        method: ReadingTextScaleChangeMethod
    ) {
        log("reading_text_scale_changed", parameters: [
            "value": value,
            "method": method.rawValue
        ])
    }

    static func trackPaywallViewed(origin: PaywallOrigin) {
        log("paywall_viewed", parameters: [
            "origin": origin.rawValue
        ])
    }

    static func syncUserProperties(
        profile: UserFaithProfile,
        cohort: SubscriptionCohort,
        access: Access?
    ) {
        setReadingTradition(profile.tradition)
        setDepthPreference(profile.explanationDepth)
        setUserProperty(cohort == .new ? "new" : "legacy", name: "cohort")
        setAccess(access)
    }

    static func setReadingTradition(_ tradition: FaithTradition) {
        setUserProperty(tradition.rawValue, name: "reading_tradition")
    }

    static func setDepthPreference(_ depth: ExplanationDepth) {
        setUserProperty(depth.analyticsName, name: "depth_preference")
    }

    private static func setAccess(_ access: Access?) {
        let previous = defaults.string(forKey: Keys.lastAccess)

        if access == .essential, previous != Access.essential.rawValue {
            log("essential_mode_entered")
        }

        if let access {
            defaults.set(access.rawValue, forKey: Keys.lastAccess)
            setUserProperty(access.rawValue, name: "access")
        } else {
            defaults.removeObject(forKey: Keys.lastAccess)
            setUserProperty(nil, name: "access")
        }
    }

    private static func logOnce(
        _ name: String,
        key: String,
        parameters: [String: Any]? = nil
    ) {
        guard defaults.object(forKey: key) == nil else { return }
        guard log(name, parameters: parameters) else { return }
        defaults.set(true, forKey: key)
    }

    @discardableResult
    private static func log(
        _ name: String,
        parameters: [String: Any]? = nil
    ) -> Bool {
        guard isConfigured else { return false }
        Analytics.logEvent(name, parameters: parameters)
        return true
    }

    private static func setUserProperty(_ value: String?, name: String) {
        guard isConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
    }
}

private extension SubscriptionPlan {
    var analyticsName: String {
        switch self {
        case .monthly: "monthly"
        case .yearly: "yearly"
        }
    }
}

private extension PauseCycleTurn {
    var analyticsName: String {
        switch self {
        case .morning: "manha"
        case .afternoon: "tarde"
        case .evening: "noite"
        }
    }
}

private extension ExplanationDepth {
    var analyticsName: String {
        switch self {
        case .short: "curta"
        case .medium: "media"
        case .deep: "profunda"
        }
    }
}
