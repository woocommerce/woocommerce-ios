import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader due to a critically low battery.
///
final class CardPresentModalConnectingFailedChargeReader: CardPresentPaymentsModalViewModel {
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

    var accessibilityLabel: String? {
        return topTitle
    }

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

private extension CardPresentModalConnectingFailedChargeReader {
    enum Localization {
        static let title = NSLocalizedString(
            "We couldn't connect your reader",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to it having a critically low battery"
        )

        static let subtitle = NSLocalizedString(
            "The reader has a critically low battery. Please charge the reader or try a different reader.",
            comment: "Subtitle of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to it having a critically low battery"
        )

        static let retry = NSLocalizedString(
            "Try Again",
            comment: "Button to try again after connecting to a specific reader fails due to a critically low battery."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to a critically low " +
            "battery. This also cancels searching."
        )
    }
}
