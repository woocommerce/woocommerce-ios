import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel {
    let title: String = Localization.title
    let image: Image
    let progressTitle: String
    let progressSubtitle: String = Localization.messageRequired
    let cancelButtonTitle: String
    let cancelReaderUpdate: (() -> Void)?

    init(progress: Float, cancel: (() -> Void)?) {
        self.image = Image(uiImage: .softwareUpdateProgress(progress: CGFloat(progress)))
        self.progressTitle = String(format: Localization.percentCompleteFormat, 100 * progress)

        self.cancelButtonTitle = Localization.cancelRequiredButtonText
        self.cancelReaderUpdate = cancel
    }
}

private extension PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.requiredReaderUpdateInProgress.title",
            value: "Updating software",
            comment: "Dialog title that displays when a software update is being installed"
        )

        static let messageRequired = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.requiredReaderUpdateInProgress.message",
            value: "Your card reader software needs to be updated to collect payments. Cancelling will block your reader connection.",
            comment: "Label that displays when a mandatory software update is happening"
        )

        static let cancelRequiredButtonText = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.requiredReaderUpdateInProgress.button.cancel.title",
            value: "Cancel anyway",
            comment: "Label for a cancel button when a mandatory software update is happening"
        )

        static let percentCompleteFormat = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.requiredReaderUpdateInProgress.progress.format",
            value: "%.0f%% complete",
            comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
        )
    }
}
