import Foundation

struct PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionSuccess.imageName
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel

    init(doneAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.done,
            actionHandler: doneAction)
    }
}

private extension PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectionSuccess.title",
            value: "Reader connected",
            comment: "Title of the alert presented when the user successfully connects a Bluetooth card reader"
        )

        static let done = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectionSuccess.done.button.title",
            value: "Done",
            comment: "Button to dismiss the alert presented when successfully connected to a reader"
        )
    }
}
