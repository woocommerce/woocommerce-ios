import UIKit

final class CardPresentModalUpdateFailed: CardPresentPaymentsModalViewModel {
    private let close: () -> Void

    /// The error returned by the stack
    private let error: Error

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .oneAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.dismiss

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? {
        error.localizedDescription
    }

    let bottomSubtitle: String? = nil

    init(error: Error, close: @escaping () -> Void) {
        self.error = error
        self.close = close
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        close()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) { }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalUpdateFailed {
    enum Localization {
        static let title = NSLocalizedString(
            "Software update failed",
            comment: "Error message. Presented to users when updating the card reader software fails"
        )

        static let dismiss = NSLocalizedString(
            "Dismiss",
            comment: "Button to dismiss. Presented to users when updating the card reader software fails"
        )
    }
}
