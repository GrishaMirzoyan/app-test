import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Customises the shield shown over a gated app with reward-framed copy and a
/// "Learn to unlock" primary button. Tokens are opaque — we never try to read
/// or display the app's real name; we use generic, encouraging language.
///
/// VERIFY (device-only): the shield cannot be rendered in the simulator. Confirm
/// the layout/strings on a real device. The exact `ShieldConfiguration` and
/// `ShieldConfiguration.Label` initialisers are noted in VERIFY.md.
final class ShieldConfigurationProvider: ShieldConfigurationDataSource {
    private func gateConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: nil,
            icon: UIImage(systemName: "brain.head.profile"),
            title: ShieldConfiguration.Label(
                text: "Earn your break", color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Do a few quick flashcard reps in Lexicon Lock to unlock this.",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Learn to unlock", color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        gateConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        gateConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        gateConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        gateConfiguration()
    }
}
