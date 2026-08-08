import AppTrackingTransparency
import FacebookCore
import FirebaseCore
import Observation
import SwiftUI
import UIKit
@preconcurrency import GoogleMobileAds
@preconcurrency import UserNotifications

@main
struct LimiarApp: App {
    @UIApplicationDelegateAdaptor(LimiarAppDelegate.self) private var appDelegate
    @State private var model: LimiarAppModel
    @State private var subscription = SubscriptionManager()
    @State private var notifications = LimiarNotificationCoordinator.shared

    init() {
        let appModel = LimiarAppModel()
        _model = State(initialValue: appModel)
        LimiarPrewarmCoordinator.shared.attach(model: appModel)
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .environment(subscription)
                .environment(notifications)
        }
    }
}

@MainActor
final class LimiarAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // A Apple exige o delegate antes do fim do lançamento para não perder
        // o toque que iniciou um cold launch pela notificação.
        UNUserNotificationCenter.current().delegate = LimiarNotificationCoordinator.shared
        LimiarPrewarmCoordinator.shared.register()
        FirebaseApp.configure()
        return MetaAppEvents.initialize(
            application: application,
            launchOptions: launchOptions
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MetaAppEvents.activateApp()
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            open: url,
            options: options
        )
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            continue: userActivity
        )
    }
}

@MainActor
@Observable
final class LimiarNotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LimiarNotificationCoordinator()
    static let bridgeIdentifier = "shield.bridge"
    nonisolated static let bridgeSource = "shield_bridge"
    static let prePromptTitle = "Um atalho para sua travessia"
    static let prePromptMessage = "Quando seus apps estiverem em pausa, o Limiar te envia um toque para abrir a leitura na hora. Também usamos isso para o lembrete da sua pausa diária."

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var shieldBridgeRouteID: UUID?

    private override init() {
        super.init()
        Task { await refreshAuthorizationStatus() }
    }

    var authorizationStatusLabel: String {
        switch authorizationStatus {
        case .notDetermined:
            "Ainda não configuradas"
        case .denied:
            "Desativadas"
        case .authorized:
            "Autorizadas"
        case .provisional:
            "Autorizadas provisoriamente"
        case .ephemeral:
            "Autorizadas temporariamente"
        @unknown default:
            "Estado desconhecido"
        }
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func handleAppDidBecomeActive() {
        clearBridgeNotification()
        Task { await refreshAuthorizationStatus() }
    }

    private func activateShieldBridgeRoute() {
        shieldBridgeRouteID = UUID()
        clearBridgeNotification()
    }

    private func clearBridgeNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.bridgeIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.bridgeIdentifier])
        Task { try? await center.setBadgeCount(0) }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let source = notification.request.content.userInfo["source"] as? String
        if source == Self.bridgeSource {
            // O app já está visível; não há motivo para mostrar um banner que
            // apenas abriria a tela em que a pessoa já se encontra.
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let source = response.notification.request.content.userInfo["source"] as? String

        if source == Self.bridgeSource {
            Task { @MainActor [weak self] in
                self?.activateShieldBridgeRoute()
            }
        }
        completionHandler()
    }
}

@MainActor
enum MetaAppEvents {
    private static let completedRegistrationKey = "limiar.meta.completedRegistration"
    private static let startedTrialKey = "limiar.meta.startedTrial"
    private static let pauseConfiguredKey = "limiar.meta.pauseConfigured"
    private static let checkoutStartedEvent = AppEvents.Name("LimiarCheckoutStarted")
    private static let subscriptionActivatedEvent = AppEvents.Name("LimiarSubscriptionActivated")
    private static let readingCompletedEvent = AppEvents.Name("LimiarReadingCompleted")
    private static let pauseConfiguredEvent = AppEvents.Name("LimiarPauseConfigured")
    private static var didInitializeSDK = false

    /// `true` enquanto a pessoa ainda não respondeu ao alerta do sistema. Serve
    /// para quem agenda outros alertas não empilhar um em cima do outro: o
    /// iOS descarta o segundo em vez de enfileirá-lo.
    static var isTrackingPromptPending: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .notDetermined
    }

    static func requestTrackingPermissionIfNeeded() {
        guard isTrackingPromptPending else { return }
        // O iOS só exibe o alerta com o app ativo. Registrar o evento com o
        // app em background inflaria att_prompt_shown sem alerta real
        // (razão shown/result ficava acima de 1).
        guard UIApplication.shared.applicationState == .active else { return }

        LimiarAnalytics.trackATTPromptShown()
        ATTrackingManager.requestTrackingAuthorization { status in
            // Qualquer resposta vale: o SDK lê o status do ATT sozinho e só
            // decide se pode vincular os eventos a um perfil. Reativamos a
            // sessão para que o próximo lote já carregue o novo status.
            Task { @MainActor in
                LimiarAnalytics.trackATTPromptResult(granted: status == .authorized)
                activateApp()
            }
        }
    }

    static func trackCompletedRegistration() {
        trackAfterAuthorization(event: .completedRegistration, defaultsKey: completedRegistrationKey)
    }

    static func trackStartedTrial() {
        trackAfterAuthorization(event: .startTrial, defaultsKey: startedTrialKey)
    }

    static func trackPaywallViewed() {
        trackAfterAuthorization(event: .viewedContent)
    }

    static func trackCheckoutStarted() {
        trackAfterAuthorization(event: checkoutStartedEvent)
    }

    static func trackSubscriptionActivated(originalTransactionID: UInt64) {
        trackAfterAuthorization(
            event: subscriptionActivatedEvent,
            defaultsKey: "limiar.meta.subscriptionActivated.\(originalTransactionID)"
        )
    }

    static func trackReadingCompleted() {
        trackAfterAuthorization(event: readingCompletedEvent)
    }

    static func trackPauseConfigured() {
        trackAfterAuthorization(event: pauseConfiguredEvent, defaultsKey: pauseConfiguredKey)
    }

    static func initialize(
        application: UIApplication = .shared,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard !didInitializeSDK else {
            return true
        }

        didInitializeSDK = true
        let result = ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        return result
    }

    static func activateApp() {
        // Os eventos seguem para a Meta em qualquer status de ATT: quem
        // recusou contribui de forma agregada (SKAdNetwork e modelagem);
        // o SDK só usa o IDFA quando a pessoa autorizou.
        _ = initialize()
        AppEvents.shared.activateApp()
        AppEvents.shared.flush()
    }

    private static func trackAfterAuthorization(event: AppEvents.Name, defaultsKey: String? = nil) {
        if let defaultsKey, UserDefaults.standard.bool(forKey: defaultsKey) {
            return
        }

        log(event, defaultsKey: defaultsKey)
    }

    private static func log(_ event: AppEvents.Name, defaultsKey: String?) {
        _ = initialize()
        guard didInitializeSDK else { return }

        AppEvents.shared.logEvent(event)
        AppEvents.shared.flush()
        if let defaultsKey {
            UserDefaults.standard.set(true, forKey: defaultsKey)
        }
    }
}
