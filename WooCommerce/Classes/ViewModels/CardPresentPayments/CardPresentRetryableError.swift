import UIKit

/// Modal presented on error. Provides a retry action.
final class CardPresentModalRetryableError: CardPresentPaymentsModalViewModel {
    private let primaryAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(primaryAction: @escaping () -> Void) {
        self.primaryAction = primaryAction
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.primaryAction()
        })
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalRetryableError {
    enum Localization {
        static let title = NSLocalizedString(
            "Something went wrong",
            comment: "Error message presented to users after a failure occurs"
        )

        static let tryAgain = NSLocalizedString(
            "Try Again",
            comment: "Button to try again. Presented to users after a failure occurs"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to cancel (not try again). Presented to users after a failure occurs"
        )
    }
}
