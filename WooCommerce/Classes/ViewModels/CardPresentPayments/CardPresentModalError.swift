import UIKit

/// Modal presented on error
final class CardPresentModalError: CardPresentPaymentsModalViewModel {

    /// Aount charged
    private let amount: String

    /// The error returned by the stack
    private let error: Error

    /// A closure to ececute when the primary button is tapped
    private let tryAgainAction: () -> Void

    let mode: PaymentsModalMode = .oneActionButton

    let topTitle: String = Localization.paymentFailed

    var topSubtitle: String? {
        amount
    }

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    init(amount: String, error: Error, tryAgain: @escaping () -> Void) {
        self.amount = amount
        self.error = error
        self.tryAgainAction = tryAgain
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tryAgainAction()
        viewController?.dismiss(animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true)
    }
}

private extension CardPresentModalError {
    enum Localization {
        static let paymentFailed = NSLocalizedString(
            "Payment failed",
            comment: "Error message. Presented to users after a collecting a payment fails"
        )

        static let tryAgain = NSLocalizedString(
            "Try collecting payment again",
            comment: "Button to try to collect a payment again. Presented to users after a collecting a payment fails"
        )
    }
}
