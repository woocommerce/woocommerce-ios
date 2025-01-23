import Foundation

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    let isPOSCashEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.acceptCashForPointOfSale)

    let title = Localization.title
    let connectReaderButtonTitle = Localization.collectPayment
    var instruction: String {
        isPOSCashEnabled ? Localization.instruction : Localization.cardOnlyInstruction
    }
}

private extension PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnected.title",
            value: "Reader not connected",
            comment: "Error message. Presented to users when card reader is not connected on the Point of Sale Checkout"
        )

        static let cardOnlyInstruction = NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnected.instruction",
            value: "To process this payment, please connect your reader.",
            comment: "Instruction to merchants shown on the Point of Sale Checkout, so they can take a card payment."
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
