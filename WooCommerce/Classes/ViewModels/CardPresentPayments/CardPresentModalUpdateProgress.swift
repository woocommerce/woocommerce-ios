import UIKit

/// Modal presented when a firmware update is being installed
///
final class CardPresentModalUpdateProgress: CardPresentPaymentsModalViewModel {
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

    init(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) {
        self.cancelAction = cancel

        let isComplete = progress == 1
        topTitle = isComplete ? Localization.titleComplete : Localization.title
        image = .softwareUpdateProgress(progress: CGFloat(progress))
        bottomTitle = String(format: Localization.percentComplete, 100 * progress)
        if !isComplete {
            bottomSubtitle = requiredUpdate ? Localization.messageRequired : Localization.messageOptional
        }
        actionsMode = cancel != nil ? .secondaryOnlyAction : .none
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


        static let percentComplete = NSLocalizedString(
            "%.0f%% complete",
            comment: "Label that describes the completed progress of a software update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
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
