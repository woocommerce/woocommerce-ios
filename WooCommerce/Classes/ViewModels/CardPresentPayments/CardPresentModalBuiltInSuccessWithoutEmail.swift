import UIKit

/// Modal presented when the payment has been collected successfully
final class CardPresentModalBuiltInSuccessWithoutEmail: CardPresentPaymentsModalViewModel {

    /// Closure to execute when primary button is tapped
    private let printReceiptAction: () -> Void

    /// Closure to execute when secondary button is tapped
    private let noReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.paymentSuccessful

    var topSubtitle: String? = nil

    let image: UIImage = .builtInReaderSuccess

    let primaryButtonTitle: String? = Localization.printReceipt

    let secondaryButtonTitle: String? = Localization.saveReceiptAndContinue

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return Localization.paymentSuccessful
    }

    init(printReceipt: @escaping () -> Void,
         noReceiptAction: @escaping () -> Void) {
        self.printReceiptAction = printReceipt
        self.noReceiptAction = noReceiptAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.printReceiptAction()
        })
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.noReceiptAction()
        }
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

// CardPresentPaymentsModalViewModelActions
/// In the adapted version of the card reader, receipt presentation can be separated from the payment alerts.
/// The existing print/email handlers won't work directly, as they rely on being able to present a receipt view controller
/// As a step towards this, we'll only provide the "Save and continue" button here.
// TODO: Consider changing the text of this button
extension CardPresentModalBuiltInSuccessWithoutEmail {
    var primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        CardPresentPaymentsModalButtonViewModel(title: Localization.saveReceiptAndContinue,
                                                actionHandler: noReceiptAction)
    }

    var secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        nil
    }

    var auxiliaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        nil
    }
}

private extension CardPresentModalBuiltInSuccessWithoutEmail {
    enum Localization {
        static let paymentSuccessful = NSLocalizedString(
            "Payment successful",
            comment: "Label informing users that the payment succeeded. Presented to users when a payment is collected"
        )

        static let printReceipt = NSLocalizedString(
            "Print receipt",
            comment: "Button to print receipts. Presented to users after a payment has been successfully collected"
        )

        static let saveReceiptAndContinue = NSLocalizedString(
            "Save receipt and continue",
            comment: "Button when the user does not want to print the receipt. Presented to users after a payment has been successfully collected"
        )
    }
}
