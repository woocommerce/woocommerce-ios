import UIKit

/// Confirms that Woo cancelled a payment after Apple's Tap to Pay UI had already shown card-read success.
final class CardPresentModalTapToPayPaymentCancelled: CardPresentPaymentsModalViewModel {
    private let onDismiss: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction
    let topTitle: String = Localization.title
    let topSubtitle: String? = nil
    let image: UIImage = .tapToPayReaderError
    let primaryButtonTitle: String? = Localization.done
    let secondaryButtonTitle: String? = nil
    let auxiliaryButtonTitle: String? = nil
    let bottomTitle: String? = Localization.noPaymentTaken
    let bottomSubtitle: String? = Localization.cardReadExplanation
    let accessibilityLabel: String? = Localization.accessibilityLabel

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        onDismiss()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalTapToPayPaymentCancelled {
    enum Localization {
        static let title = NSLocalizedString(
            "cardPresentPayment.tapToPay.paymentCancelled.title",
            value: "Payment canceled",
            comment: "Title confirming that a Tap to Pay payment was canceled in WooCommerce."
        )

        static let noPaymentTaken = NSLocalizedString(
            "cardPresentPayment.tapToPay.paymentCancelled.noPaymentTaken",
            value: "No payment was taken.",
            comment: "Message confirming that a canceled Tap to Pay payment did not charge the customer."
        )

        static let cardReadExplanation = NSLocalizedString(
            "cardPresentPayment.tapToPay.paymentCancelled.cardReadExplanation",
            value: "The Tap to Pay checkmark and sound only confirmed that the card was read.",
            comment: "Explains that Apple's Tap to Pay success feedback did not mean the canceled payment was completed."
        )

        static let done = NSLocalizedString(
            "cardPresentPayment.tapToPay.paymentCancelled.done",
            value: "Done",
            comment: "Button dismissing confirmation of a canceled Tap to Pay payment."
        )

        static let accessibilityLabel = NSLocalizedString(
            "cardPresentPayment.tapToPay.paymentCancelled.accessibilityLabel",
            value: "Payment canceled. No payment was taken. The Tap to Pay checkmark and sound only confirmed that the card was read.",
            comment: "VoiceOver summary confirming that a Tap to Pay payment was canceled without charging the customer."
        )
    }
}
