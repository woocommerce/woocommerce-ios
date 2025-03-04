import Foundation

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    let title = Localization.title
    let connectReaderButtonTitle = Localization.collectPayment
    var instruction: String {
        Localization.instruction
    }
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
            "pointOfSale.cardPresent.connectReader.button.title",
            value: "Connect your reader",
            comment: "Button to connect to the card reader, shown on the Point of Sale Checkout as a primary CTA."
        )
    }
}
