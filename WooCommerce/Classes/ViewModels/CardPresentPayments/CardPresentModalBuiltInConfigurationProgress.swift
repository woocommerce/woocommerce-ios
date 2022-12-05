import UIKit

/// Modal presented when a firmware update is being installed
///
final class CardPresentModalBuiltInConfigurationProgress: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: (() -> Void)?

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode

    var topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    var bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        Localization.title
    }

    init(progress: Float, cancel: (() -> Void)?) {
        self.cancelAction = cancel

        let isComplete = progress == 1
        topTitle = isComplete ? Localization.titleComplete : Localization.title
        image = .softwareUpdateProgress(progress: CGFloat(progress))
        bottomTitle = String(format: Localization.percentComplete, 100 * progress)
        bottomSubtitle = isComplete ? Localization.messageComplete : Localization.message
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

        static let percentComplete = NSLocalizedString(
            "%.0f%% complete",
            comment: "Label that describes the completed progress of a software update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
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
