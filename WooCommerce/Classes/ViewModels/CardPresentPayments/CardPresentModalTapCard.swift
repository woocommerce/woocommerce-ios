import UIKit
import Yosemite

/// Modal presented when the card reader requests customers to tap/insert/swipe the card
final class CardPresentModalTapCard: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    /// Cancellation callback
    private let onCancel: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.readerIsReady

    let bottomSubtitle: String?

    let accessibilityLabel: String?

    init(name: String,
         amount: String,
         transactionType: CardPresentTransactionType,
         inputMethods: CardReaderInput,
         onCancel: @escaping () -> Void) {
        self.name = name
        self.amount = amount

        if inputMethods == [.swipe, .insert, .tap] {
            self.bottomSubtitle = Localization.tapInsertOrSwipe(transactionType: transactionType)
        } else if inputMethods == [.tap, .insert] {
            self.bottomSubtitle = Localization.tapOrInsert(transactionType: transactionType)
        } else if inputMethods.contains(.tap) {
            self.bottomSubtitle = Localization.tap(transactionType: transactionType)
        } else if inputMethods.contains(.insert) {
            self.bottomSubtitle = Localization.insert(transactionType: transactionType)
        } else {
            self.bottomSubtitle = Localization.presentCard(transactionType: transactionType)
        }

        self.accessibilityLabel = Localization.readerIsReady + Localization.tapInsertOrSwipe(transactionType: transactionType)
        self.onCancel = onCancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.onCancel()
        })
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalTapCard {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Reader is ready",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static func tapInsertOrSwipe(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Tap, insert or swipe to pay",
                    comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
                )
            case .refund:
                return NSLocalizedString(
                    "Tap, insert or swipe to refund",
                    comment: "Label asking users to present a card. Presented to users when an in-person refund is going to be executed"
                )
            }
        }

        static func tapOrInsert(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Tap or insert card to pay",
                    comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
                )
            case .refund:
                return NSLocalizedString(
                    "Tap or insert card to refund",
                    comment: "Label asking users to present a card. Presented to users when an in-person refund is going to be executed"
                )
            }
        }

        static func tap(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Tap card to pay",
                    comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
                )
            case .refund:
                return NSLocalizedString(
                    "Tap card to refund",
                    comment: "Label asking users to present a card. Presented to users when an in-person refund is going to be executed"
                )
            }
        }

        static func insert(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Insert card to pay",
                    comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
                )
            case .refund:
                return NSLocalizedString(
                    "Insert card to refund",
                    comment: "Label asking users to present a card. Presented to users when an in-person refund is going to be executed"
                )
            }
        }

        static func presentCard(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Present card to pay",
                    comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
                )
            case .refund:
                return NSLocalizedString(
                    "Present card to refund",
                    comment: "Label asking users to present a card. Presented to users when an in-person refund is going to be executed"
                )
            }
        }

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to cancel a payment"
        )
    }
}
