import UIKit

/// Modal presented when a firmware update is being installed
///
final class CardPresentModalUpdateProgress: CardPresentPaymentsModalViewModel, CardPresentModalProgressDisplaying {
    /// Called when cancel button is tapped
    private let cancelAction: (() -> Void)?

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode

    var topSubtitle: String? = nil

    var progress: Float

    let primaryButtonTitle: String? = nil

    var secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var titleComplete: String

    var titleInProgress: String

    var messageComplete: String?

    var messageInProgress: String?

    var accessibilityLabel: String? {
        Localization.title
    }

    init(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) {
        self.progress = progress
        self.cancelAction = cancel

        actionsMode = .secondaryOnlyAction
        titleComplete = Localization.titleComplete
        titleInProgress = Localization.title
        secondaryButtonTitle = Localization.dismissButtonText

        if !isComplete {
            messageInProgress = requiredUpdate ? Localization.messageRequired : Localization.messageOptional
            secondaryButtonTitle = requiredUpdate ? Localization.cancelRequiredButtonText : Localization.cancelOptionalButtonText
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {
        if !isComplete {
            cancelAction?()
        } else {
            viewController?.dismiss(animated: true)
        }
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalUpdateProgress {
    enum Localization {
        static let title = NSLocalizedString(
            "Updating software",
            comment: "Dialog title that displays when a software update is being installed"
        )

        static let titleComplete = NSLocalizedString(
            "Software updated",
            comment: "Dialog title that displays when a software update just finished installing"
        )

        static let messageRequired = NSLocalizedString(
            "Your card reader software needs to be updated to collect payments. Cancelling will block your reader connection.",
            comment: "Label that displays when a mandatory software update is happening"
        )

        static let messageOptional = NSLocalizedString(
            "Your reader will automatically restart and reconnect after the update is complete.",
            comment: "Label that displays when an optional software update is happening"
        )

        static let cancelOptionalButtonText = NSLocalizedString(
            "CardPresentModalUpdateProgress.button.cancelOptionalButtonText",
            value: "Cancel",
            comment: "Label for a cancel button when an optional software update is happening"
        )

        static let cancelRequiredButtonText = NSLocalizedString(
            "CardPresentModalUpdateProgress.button.cancelRequiredButtonText",
            value: "Cancel anyway",
            comment: "Label for a cancel button when a mandatory software update is happening"
        )

        static let dismissButtonText = NSLocalizedString(
            "CardPresentModalUpdateProgress.button.dismissButtonText",
            value: "Dismiss",
            comment: "Label for a dismiss button when a software update has finished"
        )
    }
}
