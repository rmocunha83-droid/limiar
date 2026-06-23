import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configuration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration()
    }

    private func configuration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.02, green: 0.05, blue: 0.06, alpha: 1),
            icon: UIImage(named: "ShieldIcon") ?? UIImage(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(
                text: "Seu acesso está em pausa",
                color: UIColor(red: 0.94, green: 0.91, blue: 0.84, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "\nAbra o app Limiar, leia a jornada de hoje e toque em “Li com calma, liberar acesso”. Depois disso, estes APPs ficam liberados pelo tempo escolhido.",
                color: UIColor(red: 0.74, green: 0.75, blue: 0.75, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Abrir Limiar",
                color: UIColor(red: 0.03, green: 0.06, blue: 0.07, alpha: 1)
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.70, green: 0.81, blue: 0.72, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Agora não",
                color: UIColor(red: 0.69, green: 0.78, blue: 0.70, alpha: 0.58)
            )
        )
    }
}
