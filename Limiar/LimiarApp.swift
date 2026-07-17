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
        return true
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
