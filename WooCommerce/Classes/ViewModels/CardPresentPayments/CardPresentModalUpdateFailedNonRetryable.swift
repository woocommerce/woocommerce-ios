import UIKit

final class CardPresentModalUpdateFailedNonRetryable: CardPresentPaymentsModalViewModel {
    private let close: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.dismiss

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(close: @escaping () -> Void) {
        self.close = close
    }

    func didTapPrimaryButton(in viewController: UIViewController?) { }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        close()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalUpdateFailedNonRetryable {
    enum Localization {
        static let title = NSLocalizedString(
            "We couldn’t update your reader’s software",
            comment: "Error message. Presented to users when updating the card reader software fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss. Presented to users when updating the card reader software fails"
        )
    }
}
