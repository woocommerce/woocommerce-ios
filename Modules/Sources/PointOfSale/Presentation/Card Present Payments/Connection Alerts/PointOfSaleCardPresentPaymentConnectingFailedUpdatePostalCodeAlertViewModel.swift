import Foundation

struct PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let errorDetails = Localization.errorDetails
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

private extension PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdatePostCode.title",
            value: "Please correct your store's postcode/ZIP",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to postal code problems"
        )

        static let errorDetails = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdatePostCode.errorDetails",
            value: "You can set your store's postcode/ZIP in wp-admin > WooCommerce > Settings (General)",
            comment: "Subtitle of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to postal code problems"
        )

        static let retry = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdatePostCode.retry.button.title",
            value: "Retry After Updating",
            comment: "Button to try again after connecting to a specific reader fails due to postal code problems. " +
            "Intended for use after the merchant corrects the postal code in the store admin pages."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedUpdatePostCode.cancel.button.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to postal code " +
            "problems. This also cancels searching."
        )
    }
}
