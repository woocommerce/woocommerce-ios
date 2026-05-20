import UIKit

/// Modal presented on error. Does not provide a retry action. Shows email address which the receipt was sent to.
final class CardPresentModalNonRetryableErrorEmailSent: CardPresentPaymentsModalViewModel {

    /// Amount charged
    private let amount: String

    /// Called when the view is dismissed
    private let onDismiss: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = CardPresentModalNonRetryableError.Localization.paymentFailed

    var topSubtitle: String? {
        amount
    }

    let image: UIImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    let bottomAttributedSubtitle: NSAttributedString?


    var accessibilityLabel: String? {
        guard let bottomTitle else {
            return topTitle
        }

        return topTitle + bottomTitle
    }

    init(amount: String,
         errorDescription: String?,
         image: UIImage = .paymentErrorImage,
         email: String,
         requiresFallbackPaymentMethod: Bool = false,
         onDismiss: @escaping () -> Void) {
        self.amount = amount
        self.bottomTitle = errorDescription
        self.image = image
        self.primaryButtonTitle = CardPresentModalNonRetryableError.Localization.dismiss(requiresFallbackPaymentMethod: requiresFallbackPaymentMethod)
        self.onDismiss = onDismiss

        let formattedMessage = String(format: CardPresentModalError.Localization.receiptMessage, email)
        let attributedString = NSMutableAttributedString(string: formattedMessage)
        if let emailRange = formattedMessage.range(of: email) {
            let nsRange = NSRange(emailRange, in: formattedMessage)
            attributedString.addAttributes([.font: UIFont.footnote.bold], range: nsRange)
        }
        self.bottomAttributedSubtitle = attributedString
    }

    convenience init(amount: String, error: Error, email: String, onDismiss: @escaping () -> Void) {
        self.init(amount: amount, errorDescription: error.localizedDescription, email: email, onDismiss: onDismiss)
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let viewController else {
            onDismiss()
            return
        }
        viewController.dismiss(animated: true) { [weak self] in
            self?.onDismiss()
        }
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}
