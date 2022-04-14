import UIKit


/// Modal presented while processing a payment
final class CardPresentModalProcessing: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .none

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    let accessibilityLabel: String?

    init(name: String, amount: String, transactionType: CardPresentTransactionType) {
        self.name = name
        self.amount = amount
        self.bottomTitle = Localization.processingPayment(transactionType: transactionType)
        self.accessibilityLabel = Localization.processingPaymentAccessibilityLabel(transactionType: transactionType)
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalProcessing {
    enum Localization {
        static func processingPayment(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Processing payment...",
                    comment: "Indicates that a payment is being processed"
                )
            case .refund:
                return NSLocalizedString(
                    "Processing refund",
                    comment: "Indicates that an in-person refund is being processed"
                )
            }
        }

        static func processingPaymentAccessibilityLabel(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Processing payment",
                    comment: "VoiceOver accessibility label. Indicates that a payment is being processed"
                )
            case .refund:
                return NSLocalizedString(
                    "Refunding payment",
                    comment: "VoiceOver accessibility label. Indicates that an in-person refund is being processed"
                )
            }
        }
    }
}
