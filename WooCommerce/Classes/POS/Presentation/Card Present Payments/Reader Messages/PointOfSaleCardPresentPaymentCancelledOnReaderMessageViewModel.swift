import Foundation

struct PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel: Equatable {
    let title = Localization.cancelledOnReader
}

private extension PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel {
    enum Localization {
        static let cancelledOnReader = NSLocalizedString(
            "pointOfSale.cardPresent.cancelledOnReader.title",
            value: "Payment cancelled on reader",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )
    }
}
