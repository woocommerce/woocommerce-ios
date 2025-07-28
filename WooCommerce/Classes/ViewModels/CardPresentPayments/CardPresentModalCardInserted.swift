import UIKit

/// Modal presented when the card is inserted in the reader
///
final class CardPresentModalCardInserted: CardPresentPaymentsModalViewModel {
    private let onCancel: (() -> Void)

    let textMode: PaymentsModalTextMode = .fullInfo

    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    let topTitle: String

    let topSubtitle: String?

    let image: UIImage = .cardPresentImage

    let showLoadingIndicator = false

    var primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.title

    let bottomSubtitle: String? = nil

    let accessibilityLabel: String?

    init(name: String,
         amount: String,
         onCancel: @escaping () -> Void) {
        self.topTitle = name
        self.topSubtitle = amount
        self.onCancel = onCancel
        self.accessibilityLabel = Localization.title
    }

    func didTapPrimaryButton(in viewController: UIViewController?) { }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.onCancel()
        })
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalCardInserted {
    enum Localization {
        static let title = NSLocalizedString(
            "inPersonPayments.cardPresent.cardInserted.title",
            value: "Card inserted",
            comment: "Indicates the status of a card reader. Presented to merchants when the card is inserted to the reader"
        )

        static let cancel = NSLocalizedString(
            "inPersonPayments.cardPresent.cardInserted.cancel",
            value: "Cancel",
            comment: "Button to cancel a payment"
        )
    }
}
