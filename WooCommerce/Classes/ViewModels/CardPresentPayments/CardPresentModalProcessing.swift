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

    let bottomTitle: String? = Localization.processingPayment

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return Localization.processingPaymentAccessibilityLabel
    }

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

private extension CardPresentModalProcessing {
    enum Localization {
        static let processingPayment = NSLocalizedString(
            "Processing payment...",
            comment: "Indicates that a payment is being processed"
        )

        static let processingPaymentAccessibilityLabel = NSLocalizedString(
            "Processing payment",
            comment: "VoiceOver accessibility label. Indicates that a payment is being processed"
        )
    }
}
