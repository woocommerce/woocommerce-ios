import Foundation

struct PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel {
    let message: String = Localization.message
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(cancelAction: @escaping () -> Void) {
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelAction)
    }
}

private extension PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel {
    enum Localization {
        static let message = NSLocalizedString(
            "pointOfSale.cardPresent.preparingCardReader.message",
            value: "Preparing card reader",
            comment: "Message shown on the Point of Sale checkout while the reader is being prepared."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresent.preparingCardReader.cancel.button.title",
            value: "Cancel",
            comment: "Button to cancel preparation of the reader on the Point of Sale checkout."
        )
    }
}
