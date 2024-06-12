import Foundation
import SwiftUI

struct CardPresentPaymentFoundReaderAlertViewModel {
    let title: String
    let image = Image(uiImage: .cardReaderFound)
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

private extension CardPresentPaymentFoundReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Do you want to connect to reader %1$@?",
            comment: "Dialog title that displays the name of a found card reader"
        )

        static let connect = NSLocalizedString(
            "Connect to Reader",
            comment: "Label for a button that when tapped, starts the process of connecting to a card reader"
        )

        static let continueSearching = NSLocalizedString(
            "Keep Searching",
            comment: "Label for a button that when tapped, continues searching for card readers"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a button that when tapped, cancels the process of connecting to a card reader "
        )
    }
}
