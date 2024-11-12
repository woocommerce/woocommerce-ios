import UIKit

/// Modal presented when the payment has been collected successfully
/// Customer attached to order therefore an email receipt is sent automatically
final class CardPresentModalSuccessEmailSent: CardPresentPaymentsModalViewModel {

    /// Closure to execute when primary button is tapped
    private let printReceiptAction: () -> Void

    /// Closure to execute when secondary button is tapped.
    private let noReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = CardPresentModalSuccess.Localization.paymentSuccessful

    var topSubtitle: String? = nil

    let image: UIImage = .celebrationImage

    let primaryButtonTitle: String? = CardPresentModalSuccess.Localization.printReceipt

    let secondaryButtonTitle: String? = CardPresentModalSuccess.Localization.saveReceiptAndContinue

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(printReceipt: @escaping () -> Void,
         noReceiptAction: @escaping () -> Void,
         email: String) {
        self.printReceiptAction = printReceipt
        self.noReceiptAction = noReceiptAction
        self.bottomTitle = String(format: CardPresentModalSuccess.Localization.receiptMessage, email)
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
