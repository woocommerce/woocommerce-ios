import UIKit
import Yosemite

/// Modal presented on error
final class CardPresentModalScanningFailed: CardPresentPaymentsModalViewModel {

    /// The error returned by the stack
    private let error: Error

    /// A closure to execute when the primary button is tapped
    private let primaryAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.dismiss

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle + error.localizedDescription
    }

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
        static let title = NSLocalizedString(
            "Connecting reader failed",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader and it fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
