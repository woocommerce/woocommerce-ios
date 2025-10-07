import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingFailedLocationRequiredAlertViewModel: Hashable {
    let title = Localization.title
    let subtitle = Localization.subtitle

    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel
    let cancelButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(cancelSearchAction: @escaping () -> Void) {
        self.cancelButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.cancel,
            actionHandler: cancelSearchAction)
        self.primaryButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.openSettings,
            actionHandler: {
                guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(targetURL)
            })
    }
}

private extension PointOfSaleCardPresentPaymentConnectingFailedLocationRequiredAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedLocationRequired.title",
            value: "Enable location services to allow payments",
            comment: "A title explaining the requirement of location services for making a payment"
        )

        static let subtitle = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedLocationRequired.subtitle",
            value: "Location services permission is required to reduce fraud, prevent disputes, and ensure secure payments.",
            comment: "A subtitle explaining why location services are needed to make a payment"
        )

        static let openSettings = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedLocationRequired.openSettings.button.title",
            value: "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app to access location services"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingFailedLocationRequired.cancel.button.title",
            value: "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to " +
            "location permissions not being granted. This also cancels searching."
        )
    }
}
