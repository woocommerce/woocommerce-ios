import Foundation
import SwiftUI

struct CardPresentPaymentConnectingToReaderAlertViewModel {
    let title = Localization.title
    let image = Image(uiImage: .cardReaderConnecting)
    let instruction = Localization.instruction
}

private extension CardPresentPaymentConnectingToReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "cardPresentPayment.alert.connectingToReader.title",
            value: "Connecting to reader",
            comment: "Title label for modal dialog that appears when connecting to a card reader"
        )

        static let instruction = NSLocalizedString(
            "cardPresentPayment.alert.connectingToReader.instruction",
            value: "Please wait...",
            comment: "Label within the modal dialog that appears when connecting to a card reader"
        )
    }
}
