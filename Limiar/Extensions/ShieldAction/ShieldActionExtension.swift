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

        // A notificação continua sendo a ponte garantida. A resposta híbrida
        // também tenta a API nativa: se a Apple corrigir a autorização
        // individual numa atualização do iOS, a abertura direta passa a
        // funcionar automaticamente sem depender de um novo release nosso.
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
                // Sem notificação, a API nativa ainda é a única chance de
                // abrir diretamente nas versões que a oferecem.
                completion.openParentalControlsAppIfAvailable()
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Sua travessia está pronta"
            content.body = "Toque para abrir o Limiar, fazer sua travessia e liberar seus apps."
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
                // A extensão é efêmera. Só responder depois do completion do
                // agendamento garante que a ponte tenha sido persistida antes
                // da tentativa de abertura direta ou do fechamento.
                completion.openParentalControlsAppIfAvailable()
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

    func openParentalControlsAppIfAvailable() {
        if #available(iOS 26.5, *) {
            completionHandler(.openParentalControlsApp)
        } else {
            completionHandler(.close)
        }
    }
}
