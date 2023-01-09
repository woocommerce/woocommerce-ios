import UIKit


/// Modal presented while processing a payment
final class CardPresentModalBuiltInReaderProcessing: CardPresentPaymentsModalViewModel {

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

    let image: UIImage = .builtInReaderProcessing

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    let accessibilityLabel: String?

    init(name: String, amount: String) {
        self.name = name
        self.amount = amount
        self.bottomTitle = Localization.processingPayment
        self.accessibilityLabel = Localization.processingPaymentAccessibilityLabel
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

private extension CardPresentModalBuiltInReaderProcessing {
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
