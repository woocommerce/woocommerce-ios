import UIKit

/// Modal presented when a firmware update is being installed
///
final class CardPresentModalBuiltInConfigurationProgress: CardPresentPaymentsModalViewModel, CardPresentModalProgressDisplaying {
    /// Called when cancel button is tapped
    private let cancelAction: (() -> Void)?

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode

    var topSubtitle: String? = nil

    var progress: Float

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var titleComplete: String

    var titleInProgress: String

    var messageComplete: String?

    var messageInProgress: String?

    var accessibilityLabel: String? {
        Localization.title
    }

    init(progress: Float, cancel: (() -> Void)?) {
        self.progress = progress
        self.cancelAction = cancel

        titleComplete = Localization.titleComplete
        titleInProgress = Localization.title
        messageComplete = Localization.messageComplete
        messageInProgress = Localization.message
        actionsMode = cancel != nil ? .secondaryOnlyAction : .none
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction?()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalBuiltInConfigurationProgress {
    enum Localization {
        static let title = NSLocalizedString(
            "Configuring iPhone",
            comment: "Dialog title that displays when iPhone configuration is being updated for use as a card reader"
        )

        static let titleComplete = NSLocalizedString(
            "Configuration updated",
            comment: "Dialog title that displays when a configuration update just finished installing"
        )

        static let message = NSLocalizedString(
            "Your iPhone needs to be configured to collect payments.",
            comment: "Label that displays when a configuration update is happening"
        )

        static let messageComplete = NSLocalizedString(
            "Your phone will be ready to collect payments in a moment...",
            comment: "Dialog message that displays when a configuration update just finished installing"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
