import Foundation

struct PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    let title = Localization.title
    let collectPaymentButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(collectPaymentAction: @escaping () -> Void) {
        self.collectPaymentButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.collectPayment,
            actionHandler: collectPaymentAction)
    }
}

private extension PointOfSaleCardPresentPaymentReaderDisconnectedMessageViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.readerDisconnected.title",
            value: "Reader disconnected",
            comment: "Error message. Presented to users when reader is disconnected on the Point of Sale Checkout"
        )

        static let collectPayment =  NSLocalizedString(
            "pointOfSale.cardPresent.readerDisconnected.button.title",
            value: "Collect Payment",
            comment: "Button to try to collect a payment again. Presented to users after connecting to reader fails on the Point of Sale Checkout"
        )
    }
}
