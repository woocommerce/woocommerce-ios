import Foundation

struct PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel: Hashable {
    let title: String = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(cancelUpdateAction: @escaping () -> Void) {
        self.cancelButtonViewModel = .init(title: Localization.dismiss, actionHandler: cancelUpdateAction)
    }
}

private extension PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedNonRetryable.title",
            value: "We couldn’t update your reader’s software",
            comment: "Error message. Presented to users when updating the card reader software fails"
        )

        static let dismiss = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedNonRetryable.cancelButton.title",
            value: "Dismiss",
            comment: "Button to dismiss. Presented to users when updating the card reader software fails"
        )
    }
}
