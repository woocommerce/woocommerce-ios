import Foundation

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel {
    let title: String = Localization.title
    let message: String = Localization.message
}

private extension PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.preparingCardReader.title",
            value: "Preparing card reader",
            comment: "Title shown on the Point of Sale checkout while the reader is being prepared."
        )
        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.preparingCardReader.message",
            value: "Checking order",
            comment: "Message shown on the Point of Sale checkout while the reader is being prepared and order being checked."
        )
    }
}
