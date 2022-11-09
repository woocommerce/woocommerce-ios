import UIKit

/// Modal presented when we are connecting to a reader
///
final class CardPresentModalConnectingToLocalReader: CardPresentPaymentsModalViewModel {
    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .none

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String? = Localization.instruction

    var bottomSubtitle: String?

    var accessibilityLabel: String? {
        return topTitle + Localization.accessibilityInstruction
    }

    init() {}

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {}

    func didTapAuxiliaryButton(in viewController: UIViewController?) {}
}

private extension CardPresentModalConnectingToLocalReader {
    enum Localization {
        static let title = NSLocalizedString(
            "Preparing for payment",
            comment: "Title label for modal dialog that appears when connecting to the built in card reader"
        )

        static let instruction = NSLocalizedString(
            "Please wait...",
            comment: "Label within the modal dialog that appears when connecting to a card reader"
        )

        static let accessibilityInstruction = NSLocalizedString(
            "Please wait",
            comment: "VoiceOver Accessibility label for the instruction"
        )
    }
}
