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
        case activation
    }

    enum PaywallOrigin: String {
        case d6
        case d7
        case d8
        case settings
    }

    enum Access: String {
        case trial
        case premium
        case essential
    }

    enum PurchaseFailureReason: String {
        case cancelled
        case error
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

    static func trackGateViewed() {
        log("gate_viewed")
    }

    static func trackGatePlanSelected(_ plan: SubscriptionPlan) {
        log("gate_plan_selected", parameters: [
            "plan": plan.analyticsName
        ])
    }

    static func trackGatePurchaseStarted(_ plan: SubscriptionPlan) {
        log("gate_purchase_started", parameters: [
            "plan": plan.analyticsName
        ])
    }

    static func trackTrialStarted(
        plan: SubscriptionPlan,
        originalTransactionID: UInt64
    ) {
        logOnce(
            "trial_started",
            key: "\(Keys.trialStartedPrefix).\(originalTransactionID)",
            parameters: ["plan": plan.analyticsName]
        )
    }

    static func trackSubscriptionActivated(
        plan: SubscriptionPlan,
        originalTransactionID: UInt64
    ) {
        logOnce(
            "subscription_activated",
            key: "\(Keys.subscriptionActivatedPrefix).\(originalTransactionID)",
            parameters: ["plan": plan.analyticsName]
        )
    }

    static func trackPurchaseFailed(
        plan: SubscriptionPlan,
        reason: PurchaseFailureReason
    ) {
        log("purchase_failed", parameters: [
            "plan": plan.analyticsName,
            "reason": reason.rawValue
        ])
    }

    static func trackRestoreSucceeded() {
        log("restore_succeeded")
    }

    static func trackTraversalStarted(turn: PauseCycleTurn, cycleKey: String) {
        let localKey = "\(Keys.traversalStartedPrefix).\(cycleKey).\(turn.rawValue)"
        logOnce("travessia_started", key: localKey, parameters: [
            "turno": turn.analyticsName
        ])
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

    static func trackNarrationStarted() {
        log("narration_started")
    }

    static func trackNarrationFailed(reason: String) {
        log("narration_failed", parameters: [
            "reason": reason
        ])
    }

    static func trackPassageSaved() {
        log("passage_saved")
    }

    static func trackReviewPromptRequested() {
        log("review_prompt_requested")
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
