import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel {
    let title: String = Localization.title
    let image: Image = .init(uiImage: .softwareUpdateProgress(progress: CGFloat(1.0)))
    let progressTitle: String = .init(format: Localization.percentCompleteFormat, 100)
    let dismissButtonTitle: String = Localization.dismissButtonText
}

private extension PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateCompletion.title",
            value: "Software updated",
            comment: "Dialog title that displays when a software update just finished installing"
        )

        static let dismissButtonText = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateCompletion.button.dismiss.title",
            value: "Dismiss",
            comment: "Label for a dismiss button when a software update has finished"
        )

        static let percentCompleteFormat = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateCompletion.progress.format",
            value: "%.0f%% complete",
            comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
        )
    }
}
