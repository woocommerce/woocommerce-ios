import UIKit
import Yosemite

/// The card reader is ready.
final class CardPresentModalReaderIsReady: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = Localization.cancel

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.readerIsReady

    let bottomSubtitle: String? = Localization.tapInsertOrSwipe

    init(name: String, amount: String) {
        self.name = name
        self.amount = amount
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        let action = CardPresentPaymentAction.cancelPayment(onCompletion: nil)

        ServiceLocator.stores.dispatch(action)

        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalReaderIsReady {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Reader is ready",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tapInsertOrSwipe = NSLocalizedString(
            "Tap, insert or swipe to pay",
            comment: "Indicates the action expected from a user. Presented to users when payment collection starts"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to cancel a payment"
        )
    }
}
