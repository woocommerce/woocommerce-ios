import Foundation

struct PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel: Hashable {
    let title = Localization.title
    let errorDetails = Localization.errorDetails
    let imageName = PointOfSaleAssets.readerConnectionLowBattery.imageName
    let retryButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(retryButtonAction: @escaping () -> Void,
         cancelButtonAction: @escaping () -> Void) {
        self.retryButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.retry,
            actionHandler: retryButtonAction)
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelButtonAction)
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedChargeReader.title",
            value: "We couldn't connect your reader",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to it having a critically low battery"
        )

        static let errorDetails = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedChargeReader.error.details",
            value: "The reader has a critically low battery. Please charge the reader or try a different reader.",
            comment: "Subtitle of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to it having a critically low battery"
        )

        static let retry = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedChargeReader.retry.button.title",
            value: "Try Again",
            comment: "Button to try again after connecting to a specific reader fails due to a critically low battery."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedChargeReader.cancel.button.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to a critically low " +
            "battery. This also cancels searching."
        )
    }
}
