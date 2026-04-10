import Foundation
import enum Yosemite.CardReaderServiceError

struct PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let errorDetails: String?

    let retryButtonViewModel: CardPresentPaymentsModalButtonViewModel

    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error,
         retryButtonAction: @escaping () -> Void,
         cancelButtonAction: @escaping () -> Void) {
        switch error {
        case CardReaderServiceError.connection(let underlyingError):
            errorDetails = underlyingError.localizedDescription
        default:
            errorDetails = nil
        }

        retryButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.tryAgain,
            actionHandler: retryButtonAction)
        cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelButtonAction)
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailed.title",
            value: "We couldn't connect your reader",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails"
        )

        static let tryAgain = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailed.tryAgain.button.title",
            value: "Try again",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails. This allows the search to continue."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailed.cancel.button.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails. This also cancels searching."
        )
    }
}
