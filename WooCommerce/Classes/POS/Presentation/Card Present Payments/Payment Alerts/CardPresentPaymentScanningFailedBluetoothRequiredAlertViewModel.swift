import Foundation
import SwiftUI

struct CardPresentPaymentBluetoothRequiredAlertViewModel {
    let title = Localization.bluetoothRequired
    let image = Image(uiImage: .paymentErrorImage)
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

private extension CardPresentPaymentBluetoothRequiredAlertViewModel {
    enum Localization {
        static let bluetoothRequired = NSLocalizedString(
            "Bluetooth permission required",
            comment: "Title of the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
        )

        static let openDeviceSettings = NSLocalizedString(
            "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss the alert presented when finding a reader to connect to fails"
        )
    }
}
