import Foundation

struct PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel: Hashable {
    let title: String = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let retryButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(retryAction: @escaping () -> Void, cancelUpdateAction: @escaping () -> Void) {
        self.retryButtonViewModel = .init(title: Localization.tryAgain, actionHandler: retryAction)
        self.cancelButtonViewModel = .init(title: Localization.cancel, actionHandler: cancelUpdateAction)
    }
}

private extension PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailed.title",
            value: "We couldn’t update your reader’s software",
            comment: "Error message. Presented to users when updating the card reader software fails"
        )

        static let tryAgain = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailed.retryButton.title",
            value: "Try Again",
            comment: "Button to retry a software update. Presented to users when updating the card reader software fails"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailed.cancelButton.title",
            value: "Cancel",
            comment: "Button to dismiss. Presented to users when updating the card reader software fails"
        )
    }
}
