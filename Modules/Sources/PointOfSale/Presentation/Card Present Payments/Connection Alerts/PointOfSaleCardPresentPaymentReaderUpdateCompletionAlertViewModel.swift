import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel {
    let title: String = Localization.title
    let progressTitle: String = .init(format: Localization.percentCompleteFormat, 100.0)
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel

    init(doneAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: "",
            actionHandler: doneAction)
    }
}

extension PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(progressTitle)
        hasher.combine(buttonViewModel)
    }

    /// This can be synthesised – implemented manually to ensure it matches the `hash` function.
    static func ==(lhs: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel,
                   rhs: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.progressTitle == rhs.progressTitle &&
        lhs.buttonViewModel == rhs.buttonViewModel
    }
}

private extension PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateCompletion.title",
            value: "Software updated",
            comment: "Dialog title that displays when a software update just finished installing"
        )

        static let percentCompleteFormat = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateCompletion.progress.format",
            value: "%.0f%% complete",
            comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
        )
    }
}
