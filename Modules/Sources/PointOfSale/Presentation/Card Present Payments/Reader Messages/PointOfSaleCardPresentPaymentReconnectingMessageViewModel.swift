import Foundation

struct PointOfSaleCardPresentPaymentReconnectingMessageViewModel {
    let title = Localization.title
    let cancelReconnectionButtonTitle = Localization.cancelReconnection
}

private extension PointOfSaleCardPresentPaymentReconnectingMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.reconnecting.title",
            value: "Reconnecting reader...",
            comment: "Title shown on the Point of Sale Checkout when the card reader is reconnecting"
        )

        static let cancelReconnection = NSLocalizedString(
            "pointOfSale.cardPresent.cancelReconnection.button.title",
            value: "Cancel reconnection",
            comment: "Button to cancel card reader reconnection, shown on the Point of Sale Checkout"
        )
    }
}
