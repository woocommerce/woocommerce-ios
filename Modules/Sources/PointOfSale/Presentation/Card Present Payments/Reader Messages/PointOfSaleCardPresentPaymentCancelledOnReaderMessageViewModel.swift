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
            "pointOfSale.cardPresent.canceledOnReader.title",
            value: "Payment canceled on reader",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tryPaymentAgain =  NSLocalizedString(
            "pointOfSale.cardPresent.canceledOnReader.tryPaymentAgain.button.title",
            value: "Try payment again",
            comment: "Button to try to collect a payment again. Presented to users after " +
            "card reader canceled on the Point of Sale Checkout"
        )
    }
}
