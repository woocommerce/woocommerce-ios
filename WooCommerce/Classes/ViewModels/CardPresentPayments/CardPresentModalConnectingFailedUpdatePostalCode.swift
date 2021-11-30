import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalConnectingFailedUpdatePostalCode: CardPresentPaymentsModalViewModel {
    private let retrySearchAction: () -> Void
    private let cancelSearchAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.retry

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = Localization.subtitle

    let bottomSubtitle: String? = nil

    init(retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        self.retrySearchAction = retrySearch
        self.cancelSearchAction = cancelSearch
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        retrySearchAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalConnectingFailedUpdatePostalCode {
    enum Localization {
        static let title = NSLocalizedString(
            "Please update your postal code",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to postal code problems"
        )

        static let subtitle = NSLocalizedString(
            "You can set it in your site's admin pages on the web",
            comment: "Subtitle of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to postal code problems"
        )

        static let retry = NSLocalizedString(
            "Retry After Updating",
            comment: "Button to try again after connecting to a specific reader fails due to postal code problems. " +
            "Intended for use after the merchant corrects the postal code in the store admin pages."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to postal code " +
            "problems. This also cancels searching."
        )
    }
}
