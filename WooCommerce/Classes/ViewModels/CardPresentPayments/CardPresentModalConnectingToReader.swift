import UIKit

/// Modal presented when we are connecting to a reader
///
final class CardPresentModalConnectingToReader: CardPresentPaymentsModalViewModel {
    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .none

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardReaderConnecting

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.instruction

    var bottomSubtitle: String?

    init() {}

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {}

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalConnectingToReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "Please wait...",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )
    }
}
