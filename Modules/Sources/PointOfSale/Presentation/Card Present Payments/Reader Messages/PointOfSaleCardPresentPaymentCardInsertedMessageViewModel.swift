import Foundation

struct PointOfSaleCardPresentPaymentCardInsertedMessageViewModel: Equatable {
    let title = Localization.title
    let subtitle = Localization.subtitle
    let imageName = PointOfSaleAssets.readyForPayment.imageName
}

private extension PointOfSaleCardPresentPaymentCardInsertedMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.cardInserted.title",
            value: "Ready for payment",
            comment: "Indicates the status of a card reader. Presented to merchants when the card is inserted to the reader"
        )

        static let subtitle = NSLocalizedString(
            "pointOfSale.cardPresent.cardInserted.subtitle",
            value: "Card inserted",
            comment: "Indicates the status of a card reader. Presented to merchants when the card is inserted to the reader"
        )
    }
}
