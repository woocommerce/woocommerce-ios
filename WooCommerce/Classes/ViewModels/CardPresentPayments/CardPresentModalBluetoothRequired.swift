import UIKit
import Yosemite

/// Modal presented on error
final class CardPresentModalBluetoothRequired: CardPresentPaymentsModalViewModel {

    /// The error returned by the stack
    private let error: Error

    /// A closure to execute when the primary button is tapped
    private let primaryAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.bluetoothRequired

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.openDeviceSettings

    let secondaryButtonTitle: String? = Localization.dismiss

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    var accessibilityLabel: String? {
        return topTitle + error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    init(error: Error, primaryAction: @escaping () -> Void) {
        self.error = error
        self.primaryAction = primaryAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: {[weak self] in
            self?.primaryAction()
        })
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalBluetoothRequired {
    enum Localization {
        static let bluetoothRequired = NSLocalizedString(
            "Bluetooth permission required",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
        )

        static let openDeviceSettings = NSLocalizedString(
            "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
