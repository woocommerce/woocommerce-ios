import UIKit

/// Modal presented when the payment has been collected successfully
/// No customer attached to order therefore an email receipt is not sent automatically
/// Email receipt can be sent after payment
final class CardPresentModalSuccess: CardPresentPaymentsModalViewModel {

    /// Closure to execute when primary button is tapped
    private let printReceiptAction: () -> Void


    /// Closure to execute when secondary button is tapped
    private let emailReceiptAction: () -> Void

    /// Closure to execute when auxiliary button is tapped.
    private let noReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoActionAndAuxiliary

    let topTitle: String = Localization.paymentSuccessful

    var topSubtitle: String? = nil

    let image: UIImage = .celebrationImage

    let primaryButtonTitle: String? = Localization.printReceipt

    let secondaryButtonTitle: String? = Localization.emailReceipt

    let auxiliaryButtonTitle: String? = Localization.saveReceiptAndContinue

    let bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(printReceipt: @escaping () -> Void,
         emailReceipt: @escaping () -> Void,
         noReceiptAction: @escaping () -> Void) {
        self.printReceiptAction = printReceipt
        self.emailReceiptAction = emailReceipt
        self.noReceiptAction = noReceiptAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.printReceiptAction()
        })
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        emailReceiptAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.noReceiptAction()
        }
    }
}

extension CardPresentModalSuccess {
    enum Localization {
        static let paymentSuccessful = NSLocalizedString(
            "cardPresentPaymentsModal.success.paymentSuccessful",
            value: "Payment successful",
            comment: "Label informing users that the payment succeeded. Presented to users when a payment is collected"
        )

        static let printReceipt = NSLocalizedString(
            "cardPresentPaymentsModal.success.printReceipt",
            value: "Print receipt",
            comment: "Button to print receipts. Presented to users after a payment has been successfully collected"
        )

        static let emailReceipt = NSLocalizedString(
            "cardPresentPaymentsModal.success.emailReceipt",
            value: "Email receipt",
            comment: "Button to email receipts. Presented to users after a payment has been successfully collected"
        )

        static let saveReceiptAndContinue = NSLocalizedString(
            "cardPresentPaymentsModal.success.saveReceiptAndContinue",
            value: "Save receipt and continue",
            comment: "Button when the user does not want to print or email receipt. Presented to users after a payment has been successfully collected"
        )

        static let receiptMessage = NSLocalizedString(
            "cardPresentPaymentsModal.success.receiptMessage",
            value: "A receipt has been sent to %1$@",
            comment: "Message informing the user that a receipt has been sent to their email address. %1$@ is the email address"
        )
    }
}
