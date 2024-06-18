import Foundation
import SwiftUI

struct CardPresentPaymentUpdatingReaderAlertViewModel {
    let title: String
    let image: Image
    let progressTitle: String
    let progressSubtitle: String?
    let cancelButtonTitle: String
    let cancelReaderUpdate: (() -> Void)?

    init(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) {
        self.image = Image(uiImage: .softwareUpdateProgress(progress: CGFloat(progress)))

        let isComplete = progress == 1

        self.title = isComplete ? Localization.titleComplete : Localization.title
        self.progressTitle = String(format: Localization.percentCompleteFormat, 100 * progress)
        self.progressSubtitle = isComplete ? nil : (requiredUpdate ? Localization.messageRequired : Localization.messageOptional)

        self.cancelButtonTitle = isComplete ? Localization.dismissButtonText :
        (requiredUpdate ? Localization.cancelRequiredButtonText : Localization.cancelOptionalButtonText)
        self.cancelReaderUpdate = cancel
    }
}

private extension CardPresentPaymentUpdatingReaderAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.title",
            value: "Updating software",
            comment: "Dialog title that displays when a software update is being installed"
        )

        static let titleComplete = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.title",
            value: "Software updated",
            comment: "Dialog title that displays when a software update just finished installing"
        )

        static let messageRequired = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.title",
            value: "Your card reader software needs to be updated to collect payments. Cancelling will block your reader connection.",
            comment: "Label that displays when a mandatory software update is happening"
        )

        static let messageOptional = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.title",
            value: "Your reader will automatically restart and reconnect after the update is complete.",
            comment: "Label that displays when an optional software update is happening"
        )

        static let cancelOptionalButtonText = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.button.cancelOptionalButtonText",
            value: "Cancel",
            comment: "Label for a cancel button when an optional software update is happening"
        )

        static let cancelRequiredButtonText = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.button.cancelRequiredButtonText",
            value: "Cancel anyway",
            comment: "Label for a cancel button when a mandatory software update is happening"
        )

        static let dismissButtonText = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.button.dismissButtonText",
            value: "Dismiss",
            comment: "Label for a dismiss button when a software update has finished"
        )

        static let percentCompleteFormat = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.updatingReader.progress.format",
            value: "%.0f%% complete",
            comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
        )
    }
}
