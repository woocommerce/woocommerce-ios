import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel {
    let readerIDs: [String]
    let connect: (String) -> Void
    let cancelSearch: () -> Void

    init(readerIDs: [String], selectionHandler: @escaping (String?) -> Void) {
        self.readerIDs = readerIDs
        self.connect = { readerID in
            selectionHandler(readerID)
        }
        self.cancelSearch = {
            selectionHandler(nil)
        }
    }
}

private extension PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel {
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
