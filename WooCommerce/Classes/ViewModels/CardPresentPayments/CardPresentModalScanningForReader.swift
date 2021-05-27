import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalScanningForReader: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardReaderScanning

    let primaryButtonTitle: String? = Localization.cancel

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.instruction

    var bottomSubtitle: String?

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        cancelAction()
        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {}

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalScanningForReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "Turn on your reader by pressing its power button",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )
    }
}
