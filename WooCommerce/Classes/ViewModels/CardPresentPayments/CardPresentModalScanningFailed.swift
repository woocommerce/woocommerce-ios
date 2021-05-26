import UIKit
import Yosemite

/// Modal presented on error
final class CardPresentModalScanningFailed: CardPresentPaymentsModalViewModel {

    /// The error returned by the stack
    private let error: Error

    /// A closure to execute when the primary button is tapped
    private let primaryAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.connectionFailed

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.dismiss

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        switch error {
        case CardReaderServiceError.bluetoothDenied:
            return Localization.bluetoothDenied
        default:
            return nil
        }
    }

    let bottomSubtitle: String? = nil

    init(error: Error, primaryAction: @escaping () -> Void) {
        self.error = error
        self.primaryAction = primaryAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: {[weak self] in
            self?.primaryAction()
        })
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalScanningFailed {
    enum Localization {
        static let connectionFailed = NSLocalizedString(
            "Reader connection failed",
            comment: "Error message. Presented to users when finding a reader to connect to fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )

        static let bluetoothDenied = NSLocalizedString(
            "Bluetooth permission was denied",
            comment: "Explanation in the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions")
    }
}
