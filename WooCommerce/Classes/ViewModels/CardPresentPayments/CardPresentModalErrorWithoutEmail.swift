import UIKit

/// Modal presented on error
final class CardPresentModalErrorWithoutEmail: CardPresentPaymentsModalViewModel {
    /// A closure to execute when the primary button is tapped
    private let tryAgainAction: () -> Void

    /// A closure to execute after the secondary button is tapped to dismiss the modal
    private let dismissCompletion: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .twoAction

    let topTitle: String

    var topSubtitle: String? = nil

    let image: UIImage

    let primaryButtonTitle: String?

    let secondaryButtonTitle: String?

    let auxiliaryButtonTitle: String? = nil

    let bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        guard let bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(errorDescription: String?,
         transactionType: CardPresentTransactionType,
         image: UIImage = .paymentErrorImage,
         requiresFallbackPaymentMethod: Bool = false,
         tryAgainAction: @escaping () -> Void,
         dismissCompletion: @escaping () -> Void) {
        self.topTitle = CardPresentModalError.Localization.paymentFailed(transactionType: transactionType)
        self.bottomTitle = errorDescription
        self.image = image
        self.primaryButtonTitle = CardPresentModalError.Localization.tryAgain(transactionType: transactionType)
        self.secondaryButtonTitle = CardPresentModalError.Localization.dismiss(transactionType: transactionType,
                                                                               requiresFallbackPaymentMethod: requiresFallbackPaymentMethod)
        self.tryAgainAction = tryAgainAction
        self.dismissCompletion = dismissCompletion
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        tryAgainAction()
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.dismissCompletion()
        }
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}
