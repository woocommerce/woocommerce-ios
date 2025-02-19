import UIKit

/// Modal presented on error. Shows email address which the receipt was sent to.
final class CardPresentModalErrorEmailSent: CardPresentPaymentsModalViewModel {
    /// A closure to execute when the primary button is tapped
    private let tryAgainAction: () -> Void

    /// A closure to execute after the secondary button is tapped to dismiss the modal
    private let dismissCompletion: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String?

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    let bottomAttributedSubtitle: NSAttributedString?

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(errorDescription: String?,
         transactionType: CardPresentTransactionType,
         image: UIImage = .paymentErrorImage,
         email: String,
         requiresFallbackPaymentMethod: Bool = false,
         tryAgainAction: @escaping () -> Void,
         dismissCompletion: @escaping () -> Void) {
        self.topTitle = CardPresentModalError.Localization.paymentFailed(transactionType: transactionType)
        self.bottomTitle = errorDescription
        self.image = image
        self.primaryButtonTitle = CardPresentModalError.Localization.tryAgain(transactionType: transactionType)
        self.secondaryButtonTitle = CardPresentModalError.Localization.dismiss(transactionType: transactionType,
                                                                               requiresFallbackPaymentMethod: requiresFallbackPaymentMethod)
        self.tryAgainAction = tryAgainAction
        self.dismissCompletion = dismissCompletion

        let formattedMessage = String(format: CardPresentModalError.Localization.receiptMessage, email)
        let attributedString = NSMutableAttributedString(string: formattedMessage)
        if let emailRange = formattedMessage.range(of: email) {
            let nsRange = NSRange(emailRange, in: formattedMessage)
            attributedString.addAttributes([.font: UIFont.footnote.bold], range: nsRange)
        }
        self.bottomAttributedSubtitle = attributedString
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tryAgainAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.dismissCompletion()
        }
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}
