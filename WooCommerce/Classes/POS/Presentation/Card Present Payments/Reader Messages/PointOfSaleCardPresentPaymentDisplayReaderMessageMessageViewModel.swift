import Foundation

struct PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel {
    let title: String = Localization.title
    let message: String
    let imageName = String.posProcessingPaymentImageName
}

private extension PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.displayReaderMessage.message",
            value: "Processing payment",
            comment: "Message shown on the Point of Sale checkout while the reader payment is being processed."
        )
    }
}
