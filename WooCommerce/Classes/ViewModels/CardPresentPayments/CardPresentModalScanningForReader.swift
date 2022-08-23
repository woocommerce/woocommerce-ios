import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalScanningForReader: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .newCase

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardReaderScanning

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    var auxiliaryAttributedButtonTitle: NSAttributedString? {
        // AttributtedString components
        let learnMoreLinkString = Localization.learnMoreLink
        let learnMoreTextString = NSAttributedString(string: Localization.learnMoreText)
        let url = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay.asURL()
        // AttributtedString attributes
        let learnMoreLinkAttribute = [NSAttributedString.Key.link: url]
        let attributedString = NSMutableAttributedString(string: learnMoreLinkString, attributes: learnMoreLinkAttribute)
        // AttributtedString output
        attributedString.append(learnMoreTextString)
        return attributedString
    }

    let bottomTitle: String? = Localization.instruction

    var bottomSubtitle: String?

    var accessibilityLabel: String? {
        guard let bottomTitle = bottomTitle else {
            return topTitle
        }
        return topTitle + bottomTitle
    }

    init(cancel: @escaping () -> Void) {
        self.cancelAction = cancel
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {}

    func didTapSecondaryButton(in viewController: UIViewController?) {
        cancelAction()
        viewController?.dismiss(animated: true, completion: nil)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        WebviewHelper.launch(Constants.learnMoreURL.asURL(), with: viewController)
    }
}

private extension CardPresentModalScanningForReader {
    enum Constants {
        static let learnMoreURL = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "To turn on your card reader, briefly press its power button.",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )

        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Label for a cancel button"
        )

        static let learnMoreLink = NSLocalizedString(
            "Learn more",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     This is the link to the website, and forms part of a longer sentence which it should be considered a part of.
                     """
        )

        static let learnMoreText = NSLocalizedString(
            " about In\u{2011}Person Payments",
            comment: """
                     A label prompting users to learn more about In-Person Payments"
                     \u{2011} is a special character that acts as nonbreaking hyphen for "-" in the "In-Person" string.
                     """
        )
    }
}
