import Foundation

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    let title = Localization.title
    let instruction = Localization.instruction
    let connectReaderButtonTitle = Localization.collectPayment
}

private extension PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnected.title",
            value: "Reader not connected",
            comment: "Error message. Presented to users when card reader is not connected on the Point of Sale Checkout"
        )

        static let instruction = NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnectedOrCash.instruction",
            value: "To process this payment, please connect your reader or choose cash.",
            comment: "Instruction to merchants shown on the Point of Sale Checkout when card reader is not connected."
        )

        static let collectPayment =  NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnected.button.title",
            value: "Connect to reader",
            comment: "Button to connect to the card reader, shown on the Point of Sale Checkout as a primary CTA."
        )
    }
}
