import Foundation

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel: Equatable {
    let title = Localization.cancelledOnReader
    let tryAgainButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(tryPaymentAgainButtonAction: @escaping () -> Void) {
        self.tryAgainButtonViewModel = .init(title: Localization.tryPaymentAgain,
                                             actionHandler: tryPaymentAgainButtonAction)
    }
}

private extension PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel {
    enum Localization {
        static let cancelledOnReader = NSLocalizedString(
            "pointOfSale.cardPresent.cancelledOnReader.title",
            value: "Payment cancelled on reader",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tryPaymentAgain =  NSLocalizedString(
            "pointOfSale.cardPresent.cancelledOnReader.tryPaymentAgain.button.title",
            value: "Try payment again",
            comment: "Button to try to collect a payment again. Presented to users after " +
            "card reader cancelled on the Point of Sale Checkout"
        )
    }
}
