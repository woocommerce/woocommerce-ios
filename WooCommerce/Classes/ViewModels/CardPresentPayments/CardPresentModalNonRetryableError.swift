import UIKit

/// Modal presented on error. Does not provide a retry action.
final class CardPresentModalNonRetryableError: CardPresentPaymentsModalViewModel {

    /// Amount charged
    private let amount: String

    /// Called when the view is dismissed
    private let onDismiss: () -> Void

    /// A closure to execute when the secondary button is tapped
    private let emailReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.paymentFailed

    var topSubtitle: String? {
        amount
    }

    let image: UIImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String? = CardPresentModalError.Localization.emailReceipt

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }

        return topTitle + bottomTitle
    }

    init(amount: String,
         errorDescription: String?,
         image: UIImage = .paymentErrorImage,
        requiresFallbackPaymentMethod: Bool = false,
         onDismiss: @escaping () -> Void,
         emailReceiptAction: @escaping () -> Void) {
        self.amount = amount
        self.bottomTitle = errorDescription
        self.image = image
        self.primaryButtonTitle = Localization.dismiss(requiresFallbackPaymentMethod: requiresFallbackPaymentMethod)
        self.onDismiss = onDismiss
        self.emailReceiptAction = emailReceiptAction
    }

    convenience init(amount: String,
                     error: Error,
                     onDismiss: @escaping () -> Void,
                     emailReceiptAction: @escaping () -> Void) {
        self.init(amount: amount,
                  errorDescription: error.localizedDescription,
                  onDismiss: onDismiss,
                  emailReceiptAction: emailReceiptAction)
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let viewController else {
            return onDismiss()
        }
        viewController.dismiss(animated: true) { [weak self] in
            self?.onDismiss()
        }
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        emailReceiptAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

extension CardPresentModalNonRetryableError {
    enum Localization {
        static let paymentFailed = NSLocalizedString(
            "Payment failed",
            comment: "Error message. Presented to users after collecting a payment fails"
        )

        static func dismiss(requiresFallbackPaymentMethod: Bool) -> String {
            if requiresFallbackPaymentMethod {
                return CardPresentModalError.Localization.tryAnotherPaymentMethod
            } else {
                return CardPresentModalError.Localization.dismiss
            }
        }
    }
}
