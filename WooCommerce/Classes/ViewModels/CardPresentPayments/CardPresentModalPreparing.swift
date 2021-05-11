import UIKit

/// The card reader is ready.
final class CardPresentModalPreparing: CardPresentPaymentsModalViewModel {

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

    let bottomTitle: String? = Localization.preparing

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

private extension CardPresentModalPreparing {
    enum Localization {
        static let preparing = NSLocalizedString(
            "Preparing...",
            comment: "Indicates that we are preparing a card reader. Presented to users when payment collection starts"
        )
    }
}
