import UIKit
import Yosemite

/// Modal presented when an error occurs while connecting to a reader
///
final class CardPresentModalTapToPayConnectingFailedNonRetryable: CardPresentPaymentsModalViewModel {
    private let closeAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .tapToPayReaderError

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
        case CardReaderServiceError.connection(_):
            bottomTitle = tapToPayReaderDescription(for: error)
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

extension CardPresentModalTapToPayConnectingFailedNonRetryable: ReaderConnectionUnderlyingErrorDisplaying {
    func errorDescription(underlyingError: CardReaderServiceUnderlyingError) -> String? {
        switch underlyingError {
        case .internalServiceError:
            return NSLocalizedString(
                "Sorry, we could not start Tap to Pay on iPhone. Please check your connection and try again.",
                comment: "Error message when Tap to Pay on iPhone connection experiences an unexpected internal service error."
            )
        default:
            return underlyingError.errorDescription
        }
    }
}

private extension CardPresentModalTapToPayConnectingFailedNonRetryable {
    enum Localization {
        static let title = NSLocalizedString(
            "Setup failed",
            comment: "Title of the alert presented when the user tries to start Tap to Pay on iPhone and it fails"
        )

        static let close = NSLocalizedString(
            "Close",
            comment: "This text appears as a button label used to dismiss or close modal screens and dialogs throughout the app, including screens like the coupon creation success view and Jetpack installation flow. It provides users with a way to exit or return to the previous screen without performing any additional actions."
        )
    }
}
