import ManagedSettings
@preconcurrency import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, completionHandler: completionHandler)
    }

    private func handle(
        action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        guard action == .primaryButtonPressed else {
            completionHandler(.close)
            return
        }

        // `.openParentalControlsApp` também falhou no teste comercial em
        // iOS 27 com autorização individual. A ponte por notificação é usada
        // em todas as versões para manter um único comportamento confiável.
        scheduleBridgeNotificationBeforeClosing(completionHandler: completionHandler)
    }

    private func scheduleBridgeNotificationBeforeClosing(
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        let completion = ShieldResponseCompletion(completionHandler)

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                    settings.authorizationStatus == .provisional else {
                completion.close()
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Sua travessia está pronta"
            content.body = "Toque para abrir o Limiar, ler seus 3 trechos e liberar seus apps."
            content.sound = .default
            content.userInfo = ["source": Self.bridgeSource]

            let request = UNNotificationRequest(
                identifier: Self.bridgeIdentifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )

            // Uma única ponte pode existir: toques repetidos substituem a
            // pendente/entregue em vez de empilhar banners iguais.
            center.removePendingNotificationRequests(withIdentifiers: [Self.bridgeIdentifier])
            center.removeDeliveredNotifications(withIdentifiers: [Self.bridgeIdentifier])
            center.add(request) { _ in
                // A extensão é efêmera. Fechar somente depois do completion do
                // agendamento garante que o pedido seja persistido pelo sistema.
                completion.close()
            }
        }
    }

    private static let bridgeIdentifier = "shield.bridge"
    private static let bridgeSource = "shield_bridge"
}

/// O callback é fornecido pelo ManagedSettings sem anotação Sendable, mas é
/// chamado dentro das closures Sendable do UserNotifications. O box documenta
/// e isola essa travessia entre frameworks sem alterar o contrato da Apple.
private final class ShieldResponseCompletion: @unchecked Sendable {
    private let completionHandler: (ShieldActionResponse) -> Void

    init(_ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        self.completionHandler = completionHandler
    }

    func close() {
        completionHandler(.close)
    }
}
