import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel {
    let title = Localization.title
    let message: String
    let startAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error) {
        self.message = Self.message(for: error)
        self.startAgainButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.startAgain,
            actionHandler: { })
    }

    private static func message(for error: Error) -> String {
        if let error = error as? CardReaderServiceError {
            return error.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
}

private extension PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.title",
            value: "Payment failed",
            comment: "Error message. Presented to users after collecting a payment fails on the Point of Sale Checkout"
        )

        static let startAgain = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.startAgain.button.title",
            value: "Start again",
            comment: "Title of the button used on a non-retryable card payment error from the Point of Sale Checkout " +
            "to go back and start the order from scratch.")
    }
}
