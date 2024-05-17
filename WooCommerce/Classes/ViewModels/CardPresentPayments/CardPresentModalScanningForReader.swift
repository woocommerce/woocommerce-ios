import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalScanningForReader: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryActionAndAuxiliaryButton

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardReaderScanning

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.instruction

    var bottomSubtitle: String?

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        ServiceLocator.analytics.track(.cardPresentOnboardingLearnMoreTapped)
        // TODO: Provide a handler for SwiftUI callers to present the learn more screens
        guard let viewController = viewController else {
            return
        }
        WebviewHelper.launch(Constants.learnMoreURL.asURL(), with: viewController)
    }
}

private extension CardPresentModalScanningForReader {
    enum Constants {
        static let learnMoreURL = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay
    }

    enum Localization {
        static let title = NSLocalizedString(
            "cardPresent.modalScanningForReader.title",
            value: "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "cardPresent.modalScanningForReader.instruction",
            value: "To turn on your card reader, briefly press its power button.",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )

        static let cancel = NSLocalizedString(
            "cardPresent.modalScanningForReader.cancelButton",
            value: "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
