import UIKit


/// Modal presented when the card reader requests customers to remove the card
final class CardPresentModalRemoveCard: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    let mode: PaymentsModalMode = .reducedInfo

    var topTitle: String {
        name
    }

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.removeCard

    let bottomSubtitle: String? = nil

    init(name: String, amount: String) {
        self.name = name
        self.amount = amount
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

private extension CardPresentModalRemoveCard {
    enum Localization {
        static let removeCard = NSLocalizedString(
            "Please remove card",
            comment: "Label asking users to remove card. Presented to users when a payment is in the process of being collected"
        )
    }
}
