import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader due to problems with the address
///
final class CardPresentModalConnectingFailedUpdateAddress: CardPresentPaymentsModalViewModel {
    private let adminUrl: URL?
    private let retrySearchAction: () -> Void
    private let cancelSearchAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    var primaryButtonTitle: String? {
        guard adminUrl != nil else {
            return Localization.retry
        }
        return Localization.openAdmin
    }

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    init(adminUrl: URL?, retrySearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        self.adminUrl = adminUrl
        self.retrySearchAction = retrySearch
        self.cancelSearchAction = cancelSearch
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let adminUrl = adminUrl,
              let viewController = viewController else {
            return retrySearchAction()
        }
        WebviewHelper.launch(adminUrl, with: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalConnectingFailedUpdateAddress {
    enum Localization {
        static let title = NSLocalizedString(
            "Please update your store address to proceed.",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails " +
            "due to address problems"
        )

        static let openAdmin = NSLocalizedString(
            "Enter Address",
            comment: "Button to open a webview at the admin pages, so that the merchant can update their store address " +
            "to continue setting up In Person Payments"
        )

        static let retry = NSLocalizedString(
            "Retry After Updating",
            comment: "Button to try again after connecting to a specific reader fails due to address problems. " +
            "Intended for use after the merchant corrects the address in the store admin pages."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails due to address " +
            "problems. This also cancels searching."
        )
    }
}
