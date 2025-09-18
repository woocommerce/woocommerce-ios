import Foundation

struct PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel: Hashable {
    let title = Localization.title
    let errorDetails: String
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error,
         cancelAction: @escaping () -> Void) {
        self.errorDetails = error.localizedDescription
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.dismiss,
            actionHandler: cancelAction)
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedNonRetryable.title",
            value: "Connection failed",
            comment: "Error message. Presented to users after collecting a payment fails"
        )

        static let dismiss = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedNonRetryable.dismiss.button.title",
            value: "Dismiss",
            comment: "Button to dismiss. Presented to users after collecting a payment fails"
        )
    }
}
