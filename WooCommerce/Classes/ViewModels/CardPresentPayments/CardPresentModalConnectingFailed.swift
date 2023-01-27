import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalConnectingFailed: CardPresentPaymentsModalViewModel {
    private let retrySearchAction: () -> Void
    private let cancelSearchAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(error: Error,
         retrySearch: @escaping () -> Void,
         cancelSearch: @escaping () -> Void) {
        self.retrySearchAction = retrySearch
        self.cancelSearchAction = cancelSearch

        switch error {
        case CardReaderServiceError.connection(let underlyingError):
            bottomTitle = underlyingError.localizedDescription
        default:
            break
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        retrySearchAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalConnectingFailed {
    enum Localization {
        static let title = NSLocalizedString(
            "We couldn't connect your reader",
            comment: "Title of the alert presented when the user tries to connect to a specific card reader and it fails"
        )

        static let tryAgain = NSLocalizedString(
            "Try again",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails. This allows the search to continue."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when connecting to a specific reader fails. This also cancels searching."
        )
    }
}
