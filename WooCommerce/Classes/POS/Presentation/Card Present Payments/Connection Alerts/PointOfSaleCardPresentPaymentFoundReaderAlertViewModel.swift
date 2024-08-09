import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentFoundReaderAlertViewModel {
    let title: String
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
            "pointOfSale.cardPresentPayment.alert.foundReader.title",
            value: "Do you want to connect to reader %1$@?",
            comment: "Dialog title that displays the name of a found card reader"
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
