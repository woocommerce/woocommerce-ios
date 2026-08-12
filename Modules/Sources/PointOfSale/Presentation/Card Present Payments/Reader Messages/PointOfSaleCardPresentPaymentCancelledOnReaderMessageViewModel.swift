import Foundation

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel: Equatable {
    let title: String
    let message: String?
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(tryPaymentAgainButtonAction: @escaping () -> Void) {
        self.title = Localization.cancelledOnReader
        self.message = nil
        self.tryAgainButtonViewModel = .init(title: Localization.tryPaymentAgain,
                                             actionHandler: tryPaymentAgainButtonAction)
    }

    init(paymentCancellationConfirmationAction: @escaping () -> Void) {
        self.title = Localization.paymentCanceled
        self.message = Localization.paymentCancellationConfirmation
        self.tryAgainButtonViewModel = .init(title: Localization.done,
                                             actionHandler: paymentCancellationConfirmationAction)
    }
}

private extension PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel {
    enum Localization {
        static let cancelledOnReader = NSLocalizedString(
            "pointOfSale.cardPresent.canceledOnReader.title",
            value: "Payment canceled on reader",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tryPaymentAgain =  NSLocalizedString(
            "pointOfSale.cardPresent.canceledOnReader.tryPaymentAgain.button.title",
            value: "Try payment again",
            comment: "Button to try to collect a payment again. Presented to users after " +
            "card reader canceled on the Point of Sale Checkout"
        )

        static let paymentCanceled = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCancellationConfirmation.title",
            value: "Payment canceled",
            comment: "Title confirming that a Tap to Pay payment was canceled in Point of Sale"
        )

        static let paymentCancellationConfirmation = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCancellationConfirmation.message",
            value: "No payment was taken. The Tap to Pay checkmark and sound only confirmed that the card was read.",
            comment: "Explains that Tap to Pay card reading succeeded but the payment was canceled in Point of Sale"
        )

        static let done = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCancellationConfirmation.done.button.title",
            value: "Done",
            comment: "Button dismissing the Tap to Pay payment cancellation confirmation in Point of Sale"
        )
    }
}
