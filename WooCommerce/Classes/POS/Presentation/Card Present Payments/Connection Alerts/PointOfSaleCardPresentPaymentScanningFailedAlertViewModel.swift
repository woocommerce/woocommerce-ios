import Foundation

struct PointOfSaleCardPresentPaymentScanningFailedAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel
    let errorDetails: String

    init(error: Error, endSearchAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.dismiss,
            actionHandler: endSearchAction)
        self.errorDetails = error.localizedDescription
    }
}

private extension PointOfSaleCardPresentPaymentScanningFailedAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.scanningFailed.title",
            value: "Connecting reader failed",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader and it fails"
        )

        static let dismiss = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.scanningFailed.dismiss.button.title",
            value: "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
