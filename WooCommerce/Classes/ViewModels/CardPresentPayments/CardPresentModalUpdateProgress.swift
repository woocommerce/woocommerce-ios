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

    let secondaryButtonTitle: String? = Localization.cancel

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
        actionsMode = cancel != nil ? .secondaryOnlyAction : .none
        titleComplete = Localization.titleComplete
        titleInProgress = Localization.title

        if !isComplete {
            messageInProgress = requiredUpdate ? Localization.messageRequired : Localization.messageOptional
        }
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction?()
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

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
