import UIKit

/// Modal presented on error
final class CardPresentModalError: CardPresentPaymentsModalViewModel {

    /// The error returned by the stack
    private let error: Error

    /// A closure to execute when the primary button is tapped
    private let primaryAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.paymentFailed

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = Localization.noThanks

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    init(error: Error, primaryAction: @escaping () -> Void) {
        self.error = error
        self.primaryAction = primaryAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalError {
    enum Localization {
        static let paymentFailed = NSLocalizedString(
            "Payment failed",
            comment: "Error message. Presented to users after a collecting a payment fails"
        )

        static let tryAgain = NSLocalizedString(
            "Try Collecting Again",
            comment: "Button to try to collect a payment again. Presented to users after a collecting a payment fails"
        )

        static let noThanks = NSLocalizedString(
            "Back to Order",
            comment: "Button to dismiss modal overlay. Presented to users after collecting a payment fails"
        )
    }
}
