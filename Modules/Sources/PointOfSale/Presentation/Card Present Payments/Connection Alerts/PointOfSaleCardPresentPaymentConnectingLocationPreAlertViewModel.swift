import Foundation
import SwiftUI

struct PointOfSaleCardPresentPaymentConnectingLocationPreAlertViewModel: Hashable {
    let title = Localization.title
    let subtitle = Localization.subtitle
    let detail = Localization.settings

    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(requestPermissionAction: @escaping () -> Void) {
        self.primaryButtonViewModel = CardPresentPaymentsModalButtonViewModel(
            title: Localization.continueButtonTitle,
            actionHandler: requestPermissionAction)
    }
}

private extension PointOfSaleCardPresentPaymentConnectingLocationPreAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingLocationPreAlert.title",
            value: "Enable location services to allow payments",
            comment: "A title explaining the requirement of location services for making a payment"
        )

        static let subtitle = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingLocationPreAlert.subtitle",
            value: "Location services permission is required to reduce fraud, prevent disputes, and ensure secure payments.",
            comment: "A subtitle explaining why location services are needed to make a payment"
        )

        static let settings = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingLocationPreAlert.settingsNotice",
            value: "You can change this option later in the Settings app.",
            comment: "A notice at the bottom explaining that location services can be changed in the Settings app later"
        )

        static let continueButtonTitle = NSLocalizedString(
            "pointOfSale.cardPresentPayment.alert.connectingLocationPreAlert.continue.button.title",
            value: "Continue",
            comment: "A title for CTA to present native location permission alert"
        )
    }
}
