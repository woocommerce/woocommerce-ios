import UIKit

/// Modal presented when an error occurs while connecting to a reader due to problems with the address
///
final class CardPresentModalPreparingReader: CardPresentPaymentsModalViewModel {
    let cancelAction: (() -> Void)

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let showLoadingIndicator = true

    var primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = Localization.bottomTitle

    let bottomSubtitle: String? = Localization.bottomSubitle

    var accessibilityLabel: String? {
        return topTitle
    }

    init(cancelAction: @escaping () -> Void) {
        self.cancelAction = cancelAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {

    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalPreparingReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Getting ready to collect payment",
            comment: "Title of the alert presented with a spinner while the reader is being prepared"
        )

        static let bottomTitle = NSLocalizedString(
            "Connecting to reader",
            comment: "Bottom title of the alert presented with a spinner while the reader is being prepared"
        )

        static let bottomSubitle = NSLocalizedString(
            "Please wait...",
            comment: "Bottom subtitle of the alert presented with a spinner while the reader is being prepared"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented while the reader is being prepared."
        )
    }
}
