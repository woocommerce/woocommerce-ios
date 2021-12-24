import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalConnectingFailed: CardPresentPaymentsModalViewModel {
    private let continueSearchAction: () -> Void
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

    init(continueSearch: @escaping () -> Void, cancelSearch: @escaping () -> Void) {
        self.continueSearchAction = continueSearch
        self.cancelSearchAction = cancelSearch
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        continueSearchAction()
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
