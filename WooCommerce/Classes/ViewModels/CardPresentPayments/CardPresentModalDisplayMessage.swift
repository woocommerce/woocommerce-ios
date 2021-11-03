import UIKit
import Yosemite

/// Modal presented when a (headless) card reader requests we display a message to the customer
final class CardPresentModalDisplayMessage: CardPresentPaymentsModalViewModel {

    /// Customer name
    private let name: String

    /// Charge amount
    private let amount: String

    /// Message from reader to display
    private let message: String

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

    var bottomTitle: String? {
        message
    }

    let bottomSubtitle: String? = nil

    init(name: String, amount: String, message: String) {
        self.name = name
        self.amount = amount
        self.message = message
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
