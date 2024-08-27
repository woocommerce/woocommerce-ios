import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel: Hashable {
    let title = Localization.bluetoothRequired
    let imageName = PointOfSaleAssets.readerConnectionError.imageName
    let openSettingsButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let dismissButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let errorDetails: String

    init(error: Error, endSearch: @escaping () -> Void) {
        self.openSettingsButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.openDeviceSettings,
            actionHandler: Self.openDeviceSettings)
        self.dismissButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.dismiss,
            actionHandler: endSearch)
        self.errorDetails = error.localizedDescription
    }

    private static func openDeviceSettings() {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }
}

private extension PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel {
    enum Localization {
        static let bluetoothRequired = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.bluetoothRequired.title",
            value: "Bluetooth permission required",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
        )

        static let openDeviceSettings = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.bluetoothRequired.openSettings.button.title",
            value: "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app"
        )

        static let dismiss = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.bluetoothRequired.dismiss.button.title",
            value: "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
