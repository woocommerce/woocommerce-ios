import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalBuiltInConnectingFailedNonRetryable: CardPresentPaymentsModalViewModel {
    private let closeAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .builtInReaderError

    let primaryButtonTitle: String? = Localization.close

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(error: Error,
         close: @escaping () -> Void) {
        self.closeAction = close

        switch error {
        case CardReaderServiceError.connection(let underlyingError):
            bottomTitle = underlyingError.localizedDescription
        default:
            break
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        closeAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalBuiltInConnectingFailedNonRetryable {
    enum Localization {
        static let title = NSLocalizedString(
            "Setup failed",
            comment: "Title of the alert presented when the user tries to start Tap to Pay on iPhone and it fails"
        )

        static let close = NSLocalizedString(
            "Close",
            comment: "Button to dismiss the alert presented when starting Tap to Pay on iPhone fails. This also cancels searching."
        )
    }
}
