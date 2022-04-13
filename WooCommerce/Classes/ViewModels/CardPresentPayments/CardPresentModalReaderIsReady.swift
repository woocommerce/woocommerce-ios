import UIKit
import Yosemite

/// The card reader is ready.
final class CardPresentModalReaderIsReady: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

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

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }

        return topTitle + bottomTitle
    }

    /// Closure to execute when cancel button is tapped
    private let cancelAction: () -> Void

    init(name: String,
         amount: String,
         transactionType: CardPresentTransactionType,
         cancelAction: @escaping () -> Void) {
        self.name = name
        self.amount = amount
        self.bottomSubtitle = Localization.tapInsertOrSwipe(transactionType: transactionType)
        self.cancelAction = cancelAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction()
        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalReaderIsReady {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Reader is ready",
            comment: "Indicates the status of a card reader. Presented to users when in-person payment collection or refund starts"
        )

        static func tapInsertOrSwipe(transactionType: CardPresentTransactionType) -> String {
            switch transactionType {
            case .collectPayment:
                return NSLocalizedString(
                    "Tap, insert or swipe to pay",
                    comment: "Indicates the action expected from a user. Presented to users when payment collection starts"
                )
            case .refund:
                return NSLocalizedString(
                    "Tap, insert or swipe to refund",
                    comment: "Indicates the action expected from a user. Presented to users when in-person refund starts"
                )
            }
        }

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to cancel an in-person payment or refund"
        )
    }
}
