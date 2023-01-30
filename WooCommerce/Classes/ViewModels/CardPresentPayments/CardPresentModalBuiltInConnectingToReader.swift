import UIKit

/// Modal presented when we are connecting to a reader
///
final class CardPresentModalBuiltInConnectingToReader: CardPresentPaymentsModalViewModel {
    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .none

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .preparingBuiltInReader

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = nil

    var bottomSubtitle: String? = Localization.instruction

    var accessibilityLabel: String? {
        return topTitle + Localization.instruction
    }

    init() {}

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {}

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalBuiltInConnectingToReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Preparing iPhone card reader",
            comment: "Title label for modal dialog that appears when connecting to a built in card reader"
        )

        static let instruction = NSLocalizedString(
            "The first time you connect, you may be prompted to accept Apple's Terms of Service.",
            comment: "Label within the modal dialog that appears when connecting to a built in card reader"
        )
    }
}
