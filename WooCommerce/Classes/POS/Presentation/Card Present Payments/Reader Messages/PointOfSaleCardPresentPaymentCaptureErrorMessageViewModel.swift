import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel {
    let title = Localization.title
    let message = Localization.message
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(cancelButtonAction: @escaping () -> Void) {
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelButtonAction)
    }
}

private extension PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.title",
            value: "Payment status unknown",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.message",
            value: "Due to an error from capturing payment and refreshing order, we couldn't load complete order information. " +
            "Please check the latest order separately.",
            comment: "Error message. Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresent.paymentCaptureError.cancel.button.title",
            value: "I understand that order should be checked",
            comment: "Button to dismiss payment capture error message. " +
            "Presented to users after collecting a payment fails from payment capture error on the Point of Sale Checkout"
        )
    }
}
