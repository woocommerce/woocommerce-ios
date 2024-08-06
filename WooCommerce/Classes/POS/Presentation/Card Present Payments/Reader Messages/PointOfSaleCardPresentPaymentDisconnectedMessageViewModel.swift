import Foundation

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    let title = Localization.title
    let instruction = Localization.instruction
    let connectReaderButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(connectReaderAction: @escaping () -> Void) {
        self.connectReaderButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.collectPayment,
            actionHandler: connectReaderAction)
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
            "pointOfSale.cardPresent.readerNotConnected.instruction",
            value: "To process this payment, please connect your reader.",
            comment: "Instruction to merchants shown on the Point of Sale Checkout, so they can take a card payment."
        )

        static let collectPayment =  NSLocalizedString(
            "pointOfSale.cardPresent.readerNotConnected.button.title",
            value: "Connect to reader",
            comment: "Button to connect to the card reader, shown on the Point of Sale Checkout as a primary CTA."
        )
    }
}
