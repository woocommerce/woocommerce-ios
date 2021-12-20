import UIKit

/// Modal presented when the payment has been collected successfully
final class CardPresentModalSuccessWithoutEmail: CardPresentPaymentsModalViewModel {

    /// Closure to execute when primary button is tapped
    private let printReceiptAction: () -> Void

    /// Closure to execute when secondary button is tapped
    private let noReceiptAction: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.paymentSuccessful

    var topSubtitle: String? = nil

    let image: UIImage = .celebrationImage

    let primaryButtonTitle: String? = Localization.printReceipt

    let secondaryButtonTitle: String?

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return Localization.paymentSuccessful
    }

    init(printReceipt: @escaping () -> Void,
         noReceiptTitle: String,
         noReceiptAction: @escaping () -> Void) {
        self.printReceiptAction = printReceipt
        self.noReceiptAction = noReceiptAction
        self.secondaryButtonTitle = noReceiptTitle
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

private extension CardPresentModalSuccessWithoutEmail {
    enum Localization {
        static let paymentSuccessful = NSLocalizedString(
            "Payment successful",
            comment: "Label informing users that the payment succeeded. Presented to users when a payment is collected"
        )

        static let printReceipt = NSLocalizedString(
            "Print receipt",
            comment: "Button to print receipts. Presented to users after a payment has been successfully collected"
        )
    }
}
