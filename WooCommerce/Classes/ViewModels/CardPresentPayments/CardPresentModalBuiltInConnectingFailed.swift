import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalBuiltInConnectingFailed: CardPresentPaymentsModalViewModel {
    private let continueSearchAction: () -> Void
    private let cancelSearchAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .builtInReaderError

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(error: Error,
         continueSearch: @escaping () -> Void,
         cancelSearch: @escaping () -> Void) {
        self.continueSearchAction = continueSearch
        self.cancelSearchAction = cancelSearch

        switch error {
        case CardReaderServiceError.connection(let underlyingError):
            bottomTitle = underlyingError.localizedDescription
        default:
            break
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        continueSearchAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelSearchAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalBuiltInConnectingFailed {
    enum Localization {
        static let title = NSLocalizedString(
            "We couldn't start Tap to Pay on iPhone",
            comment: "Title of the alert presented when the user tries to start Tap to Pay on iPhone and it fails"
        )

        static let tryAgain = NSLocalizedString(
            "Try again",
            comment: "Button to dismiss the alert presented when starting Tap to Pay on iPhone fails. This allows the search to continue."
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the alert presented when starting Tap to Pay on iPhone fails. This also cancels searching."
        )
    }
}
