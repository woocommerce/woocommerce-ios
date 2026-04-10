import Foundation

struct PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel: Hashable {
    let title: String = Localization.title
    let imageName = PointOfSaleAssets.readerConnectionLowBattery.imageName
    let batteryLevelInfo: String
    let retrySearchButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(batteryLevel: Double?, retrySearchAction: @escaping () -> Void, cancelUpdateAction: @escaping () -> Void) {
        self.cancelButtonViewModel = .init(title: Localization.cancel, actionHandler: cancelUpdateAction)
        self.retrySearchButtonViewModel = .init(title: Localization.retry, actionHandler: retrySearchAction)
        self.batteryLevelInfo = {
            if let batteryLevel = batteryLevel {
                return String(format: Localization.message, 100 * batteryLevel)
            } else {
                return Localization.messageNoBatteryLevel
            }
        }()
    }
}

private extension PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedLowBattery.title",
            value: "Please charge reader",
            comment: "Title of the alert presented when an update fails because the reader is low on battery."
        )

        static let message = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedLowBattery.batteryLevelInfo.1",
            value: "A reader update failed because the its battery is %.0f%% charged. Please charge the reader then try again.",
            comment: "Message presented when an update fails because the reader is low on battery. " +
                "Please leave the %.0f%% intact, as it represents the current percentage of charge."
        )

        static let messageNoBatteryLevel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedLowBattery.noBatteryLevelInfo.1",
            value: "A reader update failed because it is low on battery. Please charge the reader then try again.",
            comment: "Message presented when an update fails because the reader is low on battery."
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedLowBattery.cancelButton.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when an update fails because the reader is low on battery."
        )

        static let retry = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.readerUpdateFailedLowBattery.retryButton.title",
            value: "Try again",
            comment: "Button to retry the reader search when an update fails because the reader is low on battery."
        )
    }
}
