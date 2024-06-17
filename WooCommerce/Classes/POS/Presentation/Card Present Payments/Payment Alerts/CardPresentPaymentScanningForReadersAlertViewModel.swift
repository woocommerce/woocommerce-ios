import Foundation
import SwiftUI

struct CardPresentPaymentScanningForReadersAlertViewModel {
    let title: String = Localization.title
    let instruction: String = Localization.instruction
    let image = Image(uiImage: .cardReaderScanning)
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel

    init(endSearchAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(title: Localization.cancel,
                                                                       actionHandler: endSearchAction)
    }
}

private extension CardPresentPaymentScanningForReadersAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "cardPresent.modalScanningForReader.title",
            value: "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "cardPresent.modalScanningForReader.instruction",
            value: "To turn on your card reader, briefly press its power button.",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )

        static let cancel = NSLocalizedString(
            "cardPresent.modalScanningForReader.cancelButton",
            value: "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
