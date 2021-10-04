import UIKit

final class CardPresentModalUpdateFailed: CardPresentPaymentsModalViewModel {
    private let tryAgain: () -> Void
    private let close: () -> Void

    let textMode: PaymentsModalTextMode = .noBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String = Localization.title

    var topSubtitle: String? = nil

    let image: UIImage = .paymentErrorImage

    let primaryButtonTitle: String? = Localization.tryAgain

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String? = nil

    let bottomSubtitle: String? = nil

    init(tryAgain: @escaping () -> Void, close: @escaping () -> Void) {
        self.tryAgain = tryAgain
        self.close = close
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tryAgain()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        close()
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}

private extension CardPresentModalUpdateFailed {
    enum Localization {
        static let title = NSLocalizedString(
            "We couldn’t update your reader’s software",
            comment: "Error message. Presented to users when updating the card reader software fails"
        )

        static let tryAgain = NSLocalizedString(
            "Try Again",
            comment: "Button to retry a software update. Presented to users when updating the card reader software fails"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss. Presented to users when updating the card reader software fails"
        )
    }
}
