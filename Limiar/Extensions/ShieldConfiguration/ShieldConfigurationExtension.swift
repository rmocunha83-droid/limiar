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
            icon: UIImage(systemName: "door.left.hand.open"),
            title: ShieldConfiguration.Label(
                text: "Um limiar antes de seguir",
                color: UIColor(red: 0.94, green: 0.91, blue: 0.84, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Abra o Limiar, leia o trecho de agora e volte com mais presença. Depois disso, seu acesso fica liberado por um tempo.",
                color: UIColor(red: 0.55, green: 0.77, blue: 0.78, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Abrir o Limiar",
                color: .black
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.34, green: 0.84, blue: 0.80, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Ficar aqui",
                color: UIColor(red: 0.64, green: 0.66, blue: 0.67, alpha: 1)
            )
        )
    }
}
