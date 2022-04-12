import UIKit

/// Modal presented on error
final class CardPresentModalError: CardPresentPaymentsModalViewModel {
    /// A closure to execute when the primary button is tapped
    private let primaryAction: () -> Void

    /// A closure to execute when the secondary button is tapped
    private let secondaryAction: (UIViewController?) -> Void

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

    init(errorDescription: String?,
         transactionType: CardPresentTransactionType,
         primaryAction: @escaping () -> Void,
         secondaryAction: @escaping (_ viewController: UIViewController?) -> Void) {
        self.topTitle = Localization.paymentFailed(transactionType: transactionType)
        self.bottomTitle = errorDescription
        self.primaryButtonTitle = Localization.tryAgain(transactionType: transactionType)
        self.secondaryButtonTitle = Localization.noThanks(transactionType: transactionType)
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        primaryAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        secondaryAction(viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalError {
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

        static func noThanks(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Back to Order",
                    comment: "Button to dismiss modal overlay. Presented to users after collecting a payment fails"
                )
            case .refund:
                return NSLocalizedString(
                    "Close",
                    comment: "Button to dismiss modal overlay. Presented to users after refunding a payment fails"
                )
            }
        }
    }
}
