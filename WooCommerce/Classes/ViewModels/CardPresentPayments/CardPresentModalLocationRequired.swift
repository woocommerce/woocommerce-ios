import UIKit

/// Modal presented when location permission is denied
///
final class CardPresentModalLocationRequired: CardPresentPaymentsModalViewModel {
    private let cancel: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction
    let topTitle: String = Localization.title
    let topSubtitle: String? = nil
    let image: UIImage = .cardReaderLocationImage
    let primaryButtonTitle: String? = Localization.openSettings
    let secondaryButtonTitle: String? = Localization.dismiss
    let auxiliaryButtonTitle: String? = nil
    let bottomTitle: String? = Localization.subtitle
    let bottomSubtitle: String? = nil
    var accessibilityLabel: String? {
        return topTitle + (bottomTitle ?? "")
    }

    init(cancel: @escaping () -> Void) {
        self.cancel = cancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true)
        cancel()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalLocationRequired {
    enum Localization {
        static let title = NSLocalizedString(
            "cardPresentPayment.locationRequired.title",
            value: "Enable location services in device settings to allow payments.",
            comment: "A title explaining the requirement of location services for making a payment"
        )

        static let subtitle = NSLocalizedString(
            "cardPresentPayment.locationRequired.subtitle",
            value: "Location services permission is required to reduce fraud, prevent disputes, and ensure secure payments.",
            comment: "A subtitle explaining why location services are needed to make a payment"
        )

        static let openSettings = NSLocalizedString(
            "cardPresentPayment.locationRequired.openSettings",
            value: "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app"
        )

        static let dismiss = NSLocalizedString(
            "cardPresentPayment.locationRequired.dismiss",
            value: "Dismiss",
            comment: "Dismisses the location alert"
        )
    }
}
