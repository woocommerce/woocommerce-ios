import UIKit

/// Modal presented when a firmware update is being installed
///
final class CardPresentModalUpdateProgress: CardPresentPaymentsModalViewModel {
    /// Amount of update that has been completed
    private let progress: Float

    /// Called when cancel button is tapped
    private let cancelAction: (() -> Void)?

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode

    var topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage = .cardReaderUpdateProgressBackground

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    var bottomSubtitle: String? = Localization.message

    init(progress: Float, cancel: (() -> Void)?) {
        self.progress = progress
        self.cancelAction = cancel

        topTitle = progress == 1 ? Localization.titleComplete : Localization.title
        bottomTitle = String(format: Localization.percentComplete, 100 * progress)

        if cancel != nil {
            actionsMode = .secondaryOnlyAction
        } else {
            actionsMode = .none
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


        static let percentComplete = NSLocalizedString(
            "%.0f%% complete",
            comment: "Label that describes the completed progress of a software update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
        )

        static let message = NSLocalizedString(
            "Your card reader software needs to be updated to collect payments. Cancelling will block your reader connection.",
            comment: "Label that describes why a software update is happening")

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
