import Foundation

struct PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel: Hashable {
    let title = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionConnecting.imageName
    let instruction = Localization.instruction
}

private extension PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingToReader.title",
            value: "Connecting to reader",
            comment: "Title label for modal dialog that appears when connecting to a card reader"
        )

        static let instruction = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingToReader.instruction",
            value: "Please wait...",
            comment: "Label within the modal dialog that appears when connecting to a card reader"
        )
    }
}
