import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel: Identifiable {
    let title: String = Localization.title
    private let progress: Float
    let image: Image
    let progressTitle: String
    let progressSubtitle: String = Localization.messageRequired
    let cancelButtonTitle: String
    let cancelReaderUpdate: (() -> Void)?
    // An unchanging, psuedo-random ID helps us correctly compare two copies which may have different closures.
    // This relies on the closures being immutable
    let id = UUID()

    init(progress: Float, cancel: (() -> Void)?) {
        self.image = Image(uiImage: .softwareUpdateProgress(progress: CGFloat(progress)))
        self.progress = progress
        self.progressTitle = String(format: Localization.percentCompleteFormat, 100 * progress)

        self.cancelButtonTitle = Localization.cancelRequiredButtonText
        self.cancelReaderUpdate = cancel
    }
}

extension PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel: Hashable {
    static func == (lhs: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel,
                    rhs: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.progress == rhs.progress &&
        lhs.progressTitle == rhs.progressTitle &&
        lhs.progressSubtitle == rhs.progressSubtitle &&
        lhs.cancelButtonTitle == rhs.cancelButtonTitle &&
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(progress)
        hasher.combine(progressTitle)
        hasher.combine(progressSubtitle)
        hasher.combine(cancelButtonTitle)
        hasher.combine(id)
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
