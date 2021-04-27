import UIKit

final class CardPresentModalSuccess: CardPresentPaymentsModalViewModel {
    private let amount: String
    private let printReceiptAction: () -> Void
    private let emailReceiptAction: () -> Void

    let topTitle: String = Localization.paymentSuccessful

    var topSubtitle: String {
        amount
    }

    let image: UIImage = .celebrationImage

    let areButtonsVisible: Bool = true

    let primaryButtonTitle: String = Localization.printReceipt

    let secondaryButtonTitle: String = Localization.emailReceipt

    let isAuxiliaryButtonHidden: Bool = false

    let auxiliaryButtonTitle: String = Localization.noThanks

    let bottomTitle: String = ""

    let bottomSubtitle: String = ""

    init(amount: String, printReceipt: @escaping () -> Void, emailReceipt: @escaping () -> Void) {
        self.amount = amount
        self.printReceiptAction = printReceipt
        self.emailReceiptAction = emailReceipt
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        printReceiptAction()
        viewController?.dismiss(animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        emailReceiptAction()
        viewController?.dismiss(animated: true)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true)
    }
}

private extension CardPresentModalSuccess {
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

        static let noThanks = NSLocalizedString(
            "No thanks",
            comment: "Button to dismiss modal overlay. Presented to users after a payment has been successfully collected"
        )
    }
}
