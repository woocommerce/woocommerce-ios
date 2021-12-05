import UIKit

/// Modal presented on error. Does not provide a retry action.
final class CardPresentModalNonRetryableError: CardPresentPaymentsModalViewModel {

    /// Amount charged
    private let amount: String

    /// The error returned by the stack
    private let error: Error

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.paymentFailed

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.dismiss

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }

        return topTitle + bottomTitle
    }

    init(amount: String, error: Error) {
        self.amount = amount
        self.error = error
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalNonRetryableError {
    enum Localization {
        static let paymentFailed = NSLocalizedString(
            "Payment failed",
            comment: "Error message. Presented to users after collecting a payment fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss. Presented to users after collecting a payment fails"
        )
    }
}
