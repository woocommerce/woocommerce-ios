import UIKit

/// Modal presented when the card is inserted in the reader
///
final class CardPresentModalCardInserted: CardPresentPaymentsModalViewModel {
    let onCancel: (() -> Void)

    let textMode: PaymentsModalTextMode = .reducedTopInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryOnlyAction

    let topTitle: String = ""

    var topSubtitle: String? = nil

    let image: UIImage = .cardPresentImage

    let showLoadingIndicator = true

    var primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = nil

    let auxiliaryButtonTitle: String? = nil

    var bottomTitle: String?

    let bottomSubtitle: String? = nil

    var accessibilityLabel: String? {
        return topTitle
    }

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {

    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            self?.onCancel()
        })
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) { }
}
