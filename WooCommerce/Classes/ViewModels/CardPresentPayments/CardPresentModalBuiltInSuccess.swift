import UIKit

/// Modal presented when the payment has been collected successfully
final class CardPresentModalBuiltInSuccess: CardPresentPaymentsModalViewModel {

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

    let image: UIImage = .builtInReaderSuccess

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
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.emailReceiptAction()
        })
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.noReceiptAction()
        }
    }
}

private extension CardPresentModalBuiltInSuccess {
    enum Localization {
        static let paymentSuccessful = NSLocalizedString(
            "Payment successful",
            comment: "Label informing users that the payment succeeded. Presented to users when a payment is collected"
        )

        static let printReceipt = NSLocalizedString(
            "Print receipt",
            comment: "Button to print receipts. Presented to users after a payment has been successfully collected"
        )

        static let emailReceipt = NSLocalizedString(
            "Email receipt",
            comment: "Button to email receipts. Presented to users after a payment has been successfully collected"
        )

        static let saveReceiptAndContinue = NSLocalizedString(
            "Save receipt and continue",
            comment: "Button when the user does not want to print or email receipt. Presented to users after a payment has been successfully collected"
        )
    }
}
