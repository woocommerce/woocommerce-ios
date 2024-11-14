import UIKit

/// Modal presented when the payment has been collected successfully
/// Customer attached to order therefore an email receipt is sent automatically
final class CardPresentModalBuiltInSuccessEmailSent: CardPresentPaymentsModalViewModel {

    /// Closure to execute when primary button is tapped
    private let printReceiptAction: () -> Void

    /// Closure to execute when second button is tapped.
    private let noReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = CardPresentModalSuccess.Localization.paymentSuccessful

    let topSubtitle: String? = nil

    let image: UIImage = .builtInReaderSuccess

    let primaryButtonTitle: String? = CardPresentModalSuccess.Localization.printReceipt

    let secondaryButtonTitle: String? = CardPresentModalSuccess.Localization.saveReceiptAndContinue

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = nil

    let bottomAttributedTitle: NSAttributedString?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(printReceipt: @escaping () -> Void,
         noReceiptAction: @escaping () -> Void,
         email: String) {
        self.printReceiptAction = printReceipt
        self.noReceiptAction = noReceiptAction

        let formattedMessage = String(format: CardPresentModalSuccess.Localization.receiptMessage, email)
        let attributedString = NSMutableAttributedString(string: formattedMessage)
        if let emailRange = formattedMessage.range(of: email) {
            let nsRange = NSRange(emailRange, in: formattedMessage)
            attributedString.addAttributes([.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)], range: nsRange)
        }
        self.bottomAttributedTitle = attributedString
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
