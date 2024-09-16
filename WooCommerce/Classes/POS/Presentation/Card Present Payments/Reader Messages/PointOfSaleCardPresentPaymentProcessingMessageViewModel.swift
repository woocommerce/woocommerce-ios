import Foundation

struct PointOfSaleCardPresentPaymentProcessingMessageViewModel: Equatable {
    let message = Localization.pleaseWait
    let title = Localization.paymentProcessing
}

private extension PointOfSaleCardPresentPaymentProcessingMessageViewModel {
    enum Localization {
        static let paymentProcessing = NSLocalizedString(
            "pointOfSale.cardPresent.paymentProcessing.title",
            value: "Processing payment",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let pleaseWait = NSLocalizedString(
            "pointOfSale.cardPresent.paymentProcessing.message",
            value: "Please wait...",
            comment: "Indicates to wait while payment is processing. Presented to users when payment collection starts"
        )
    }
}
