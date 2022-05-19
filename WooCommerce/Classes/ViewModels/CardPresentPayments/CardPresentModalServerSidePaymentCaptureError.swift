import UIKit

/// Modal presented on error capturing payment on the server side.
final class CardPresentModalServerSidePaymentCaptureError: CardPresentPaymentsModalViewModel {
    /// A closure to execute when the primary button is tapped.
    private let primaryAction: () -> Void

    /// A closure to execute after the secondary button is tapped to dismiss the modal.
    private let dismissCompletion: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String?

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(primaryAction: @escaping () -> Void,
         dismissCompletion: @escaping () -> Void) {
        self.topTitle = Localization.title
        self.bottomTitle = Localization.description
        self.primaryButtonTitle = Localization.tryAgain
        self.secondaryButtonTitle = Localization.noThanks
        self.primaryAction = primaryAction
        self.dismissCompletion = dismissCompletion
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.dismissCompletion()
        }
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalServerSidePaymentCaptureError {
    enum Localization {
        static let title = NSLocalizedString(
            "Payment submission failed",
            comment: "Error title. Presented to users after collecting a payment in the app succeeds but the payment cannot be submitted to the site"
        )

        static let description = NSLocalizedString(
            "The payment hasn't been posted to the store due to an error.",
            comment: "Error description. Presented to users after collecting a payment in the app succeeds but the payment cannot be submitted to the site"
        )

        static let tryAgain = NSLocalizedString(
            "Try Again",
            comment: "Button to try to submit a payment to the site again. " +
            "Presented to users after collecting a payment in the app succeeds but the payment cannot be submitted to the site"
        )

        static let noThanks = NSLocalizedString(
            "Back to Order",
            comment: "Button to dismiss modal overlay. Presented to users after collecting a payment fails"
        )
    }
}
