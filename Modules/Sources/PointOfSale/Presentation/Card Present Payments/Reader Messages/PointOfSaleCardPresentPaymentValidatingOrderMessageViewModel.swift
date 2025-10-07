import Foundation

struct PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel: Equatable {
    let title: String = Localization.title
    let message: String = Localization.message
}

private extension PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrder.title",
            value: "Getting ready",
            comment: "Title shown on the Point of Sale checkout while the order is being validated."
        )
        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.validatingOrder.message",
            value: "Checking order",
            comment: "Message shown on the Point of Sale checkout while the order is being validated."
        )
    }
}
