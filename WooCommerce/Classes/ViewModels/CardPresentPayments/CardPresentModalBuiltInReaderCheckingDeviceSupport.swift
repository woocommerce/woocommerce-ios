import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalBuiltInReaderCheckingDeviceSupport: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryActionAndAuxiliaryButton

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .preparingBuiltInReader

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let auxiliaryButtonimage: UIImage? = .infoOutlineImage

    let bottomTitle: String? = nil

    var bottomSubtitle: String? = Localization.instruction

    var accessibilityLabel: String? {
        return topTitle + Localization.instruction
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
        guard let viewController = viewController else {
            return
        }
        WebviewHelper.launch(Constants.learnMoreURL.asURL(), with: viewController)
    }
}

private extension CardPresentModalBuiltInReaderCheckingDeviceSupport {
    enum Constants {
        static let learnMoreURL = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay
    }

    enum Localization {
        static let title = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.title",
            value: "Checking device",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.instruction",
            value: "Please wait while we check that your device is ready for Tap to Pay on iPhone.",
            comment: "Label within the modal dialog that appears when checking the built in card reader"
        )

        static let cancel = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.cancelButton",
            value: "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
