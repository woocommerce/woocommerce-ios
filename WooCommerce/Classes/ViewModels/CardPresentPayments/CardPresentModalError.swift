import UIKit

/// Modal presented on error
final class CardPresentModalError: CardPresentPaymentsModalViewModel {
    /// A closure to execute when the primary button is tapped
    private let tryAgainAction: () -> Void

    /// A closure to execute when the secondary button is tapped
    private let emailReceiptAction: () -> Void

    /// A closure to execute after the auxilary button is tapped to dismiss the modal
    private let dismissCompletion: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoActionAndAuxiliary

    let topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String? = Localization.emailReceipt

    let auxiliaryButtonTitle: String?

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        guard let bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(errorDescription: String?,
         transactionType: CardPresentTransactionType,
         image: UIImage = .paymentErrorImage,
         requiresFallbackPaymentMethod: Bool = false,
         tryAgainAction: @escaping () -> Void,
         emailReceiptAction: @escaping () -> Void,
         dismissCompletion: @escaping () -> Void) {
        self.topTitle = Localization.paymentFailed(transactionType: transactionType)
        self.bottomTitle = errorDescription
        self.image = image
        self.primaryButtonTitle = Localization.tryAgain(transactionType: transactionType)
        self.auxiliaryButtonTitle = Localization.dismiss(transactionType: transactionType,
                                                         requiresFallbackPaymentMethod: requiresFallbackPaymentMethod)
        self.tryAgainAction = tryAgainAction
        self.emailReceiptAction = emailReceiptAction
        self.dismissCompletion = dismissCompletion
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tryAgainAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        emailReceiptAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.dismissCompletion()
        }
    }
}

extension CardPresentModalError {
    enum Localization {
        static func paymentFailed(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Payment failed",
                    comment: "Error message. Presented to users after collecting a payment fails"
                )
            case .refund:
                return NSLocalizedString(
                    "Refund failed",
                    comment: "Error message. Presented to users after an in-person refund fails"
                )
            }
        }

        static func tryAgain(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Try Collecting Again",
                    comment: "Button to try to collect a payment again. Presented to users after collecting a payment fails"
                )
            case .refund:
                return NSLocalizedString(
                    "Try Again",
                    comment: "Button to try to refund a payment again. Presented to users after refunding a payment fails"
                )
            }
        }

        static func dismiss(transactionType: CardPresentTransactionType, requiresFallbackPaymentMethod: Bool) -> String {
            switch transactionType {
            case .collectPayment:
                if requiresFallbackPaymentMethod {
                    return Localization.tryAnotherPaymentMethod
                } else {
                   return Localization.backToOrder
                }
            case .refund:
                return Localization.close
            }
        }

        static let tryAnotherPaymentMethod = NSLocalizedString(
            "cardPresentPaymentsModal.error.tryAnotherPaymentMethod",
            value: "Try Another Payment Method",
            comment: "Button to dismiss modal overlay and try another payment method. Presented to users after collecting a payment fails"
        )

        static let backToOrder = NSLocalizedString(
            "cardPresentPaymentsModal.error.backToOrder",
            value: "Back to Order",
            comment: "Button to dismiss modal overlay. Presented to users after collecting a payment fails"
        )

        static let dismiss = NSLocalizedString(
            "cardPresentPaymentsModal.error.dismiss",
            value: "Dismiss",
            comment: "Button to dismiss. Presented to users after collecting a payment fails"
        )

        static let close = NSLocalizedString(
            "cardPresentPaymentsModal.error.close",
            value: "Close",
            comment: "Button to dismiss modal overlay. Presented to users after refunding a payment fails"
        )

        static let receiptMessage = NSLocalizedString(
            "cardPresentPaymentsModal.error.receiptMessage",
            value: "A receipt has been sent to %1$@",
            comment: "Message informing the user that a receipt has been sent to their email address. %1$@ is the email address"
        )

        static let emailReceipt = NSLocalizedString(
            "cardPresentPaymentsModal.error.emailReceipt",
            value: "Email receipt",
            comment: "Button to email receipts. Presented to users after a payment processing has failed"
        )
    }
}
