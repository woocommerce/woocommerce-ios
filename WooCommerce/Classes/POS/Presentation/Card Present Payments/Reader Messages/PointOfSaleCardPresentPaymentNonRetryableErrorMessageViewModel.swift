import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel {
    let title = Localization.title
    let message: String
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error,
         cancelButtonAction: @escaping () -> Void) {
        self.message = Self.message(for: error)
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelButtonAction)
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

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresent.paymentErrorNonRetryable.cancel.button.title",
            value: "Cancel Payment",
            comment: "Button to dismiss modal overlay. Presented to users after collecting a payment fails on the Point of Sale Checkout"
        )
    }
}
