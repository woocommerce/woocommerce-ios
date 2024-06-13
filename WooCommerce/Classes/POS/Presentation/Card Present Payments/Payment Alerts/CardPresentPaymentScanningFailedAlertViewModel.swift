import Foundation
import SwiftUI

struct CardPresentPaymentScanningFailedAlertViewModel {
    let title = Localization.title
    let image = Image(uiImage: .paymentErrorImage)
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel
    let errorDetails: String

    init(error: Error, endSearchAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.dismiss,
            actionHandler: endSearchAction)
        self.errorDetails = error.localizedDescription
    }
}

private extension CardPresentPaymentScanningFailedAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "Connecting reader failed",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader and it fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
