import UIKit

/// Modal presented on error
final class CardPresentModalNonRetryableError: CardPresentPaymentsModalViewModel {

    /// Amount charged
    private let amount: String

    /// The error returned by the stack
    private let error: Error

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.paymentFailed

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

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
            comment: "Error message. Presented to users after a collecting a payment fails"
        )

        static let tryAgain = NSLocalizedString(
            "Dismiss",
            comment: "Button to try to dismiss. Presented to users after a collecting a payment fails"
        )
    }
}
