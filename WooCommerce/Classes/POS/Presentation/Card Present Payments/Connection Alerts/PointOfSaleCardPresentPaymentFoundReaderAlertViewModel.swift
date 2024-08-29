import Foundation

struct PointOfSaleCardPresentPaymentFoundReaderAlertViewModel: Hashable {
    let title: String
    let description: String = Localization.description
    let imageName = PointOfSaleAssets.readerConnectionDoYouWantToConnect.imageName
    let connectButton: CardPresentPaymentsModalButtonViewModel
    let continueSearchButton: CardPresentPaymentsModalButtonViewModel
    let cancelSearchButton: CardPresentPaymentsModalButtonViewModel

    init(readerName: String,
         connectAction: @escaping () -> Void,
         continueSearchAction: @escaping () -> Void,
         endSearchAction: @escaping () -> Void) {
        self.title = String(format: Localization.title, readerName)
        self.connectButton = CardPresentPaymentsModalButtonViewModel(title: Localization.connect,
                                                                     actionHandler: connectAction)
        self.continueSearchButton = CardPresentPaymentsModalButtonViewModel(title: Localization.continueSearching,
                                                                            actionHandler: continueSearchAction)
        self.cancelSearchButton = CardPresentPaymentsModalButtonViewModel(title: Localization.cancel,
                                                                          actionHandler: endSearchAction)
    }
}

private extension PointOfSaleCardPresentPaymentFoundReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundReader.title.2",
            value: "Found %1$@",
            comment: "Dialog title that displays the name of a found card reader"
        )

        static let description = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundReader.description",
            value: "Do you want to connect to this reader?",
            comment: "Dialog description that asks the user if they want to connect to a specific found card reader. " +
            "They can instead, keep searching for more readers."
        )

        static let connect = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundReader.connect.button.title",
            value: "Connect to Reader",
            comment: "Label for a button that when tapped, starts the process of connecting to a card reader"
        )

        static let continueSearching = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundReader.keepSearching.button.title",
            value: "Keep Searching",
            comment: "Label for a button that when tapped, continues searching for card readers"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.foundReader.cancel.button.title",
            value: "Cancel",
            comment: "Label for a button that when tapped, cancels the process of connecting to a card reader "
        )
    }
}
