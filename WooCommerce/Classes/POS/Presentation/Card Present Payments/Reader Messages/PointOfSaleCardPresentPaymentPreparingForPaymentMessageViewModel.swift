import Foundation

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel: Equatable {
    let title: String = Localization.title
    let message: String = Localization.message
}

private extension PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.preparingForPayment.title",
            value: "Getting ready",
            comment: "Title shown on the Point of Sale checkout while the reader is being prepared."
        )
        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.preparingReaderForPayment.message",
            value: "Preparing reader for payment",
            comment: "Message shown on the Point of Sale checkout while the reader is being prepared."
        )
    }
}
