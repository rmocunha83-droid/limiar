import ManagedSettings

final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(response(for: action))
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(response(for: action))
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(response(for: action))
    }

    private func response(for action: ShieldAction) -> ShieldActionResponse {
        guard action == .primaryButtonPressed else { return .close }
        if #available(iOS 26.5, *) {
            return .openParentalControlsApp
        }
        // Antes do iOS 26.5 não é possível abrir o Limiar a partir do shield.
        // `.defer` deixaria o botão sem nenhum efeito visível; `.close` fecha o
        // app bloqueado e a copy do shield orienta a abrir o Limiar.
        return .close
    }
}
