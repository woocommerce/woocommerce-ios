import UIKit

/// Modal presented before requesting location permission
///
final class CardPresentModalLocationPreAlert: CardPresentPaymentsModalViewModel {
    /// Called when continue button is tapped
    private let requestPermission: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction
    let topTitle: String = Localization.title
    let topSubtitle: String? = nil
    let image: UIImage = .cardReaderLocationImage
    let primaryButtonTitle: String? = Localization.continueButton
    let secondaryButtonTitle: String? = nil
    let auxiliaryButtonTitle: String? = nil
    let bottomTitle: String? = Localization.subtitle
    let bottomSubtitle: String? = Localization.settings
    var accessibilityLabel: String? {
        return topTitle + (bottomTitle ?? "") + (bottomSubtitle ?? "")
    }

    init(requestPermission: @escaping () -> Void) {
        self.requestPermission = requestPermission
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        requestPermission()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {}

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalLocationPreAlert {
    enum Localization {
        static let title = NSLocalizedString(
            "cardPresentPayment.locationPreAlert.title",
            value: "Enable location services on the next screen to allow payments.",
            comment: "A title explaining why location services are needed to make a payment"
        )

        static let subtitle = NSLocalizedString(
            "cardPresentPayment.locationPreAlert.subtitle",
            value: "Location services permission is required to reduce fraud, prevent disputes, and ensure secure payments.",
            comment: "A subtitle explaining why location services are needed to make a payment"
        )

        static let settings = NSLocalizedString(
            "cardPresentPayment.locationPreAlert.settingsNotice",
            value: "You can change this option later in the Settings app.",
            comment: "A notice at the bottom explaining that location services can be changed in the Settings app later"
        )

        static let continueButton = NSLocalizedString(
            "cardPresentPayment.locationPreAlert.continueButton",
            value: "Continue",
            comment: "A title for CTA to present native location permission alert"
        )
    }
}
