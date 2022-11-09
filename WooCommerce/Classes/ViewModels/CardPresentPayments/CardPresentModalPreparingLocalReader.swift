import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalPreparingLocalReader: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .reducedBottomInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryActionAndAuxiliaryButton

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .cardPresentImage

    let primaryButtonTitle: String? = nil

    let secondaryButtonTitle: String? = Localization.cancel

    let auxiliaryButtonTitle: String? = nil

    let auxiliaryButtonimage: UIImage? = .infoOutlineImage

    var auxiliaryAttributedButtonTitle: NSAttributedString? {
        let result = NSMutableAttributedString(
            string: .localizedStringWithFormat(
                Localization.learnMoreText,
                Localization.learnMoreLink
            ),
            attributes: [.foregroundColor: UIColor.text]
        )
        result.replaceFirstOccurrence(
            of: Localization.learnMoreLink,
            with: NSAttributedString(
                string: Localization.learnMoreLink,
                attributes: [
                    .foregroundColor: UIColor.accent,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ))
        result.addAttribute(.font, value: UIFont.footnote, range: NSRange(location: 0, length: result.length))
        return result
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
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        ServiceLocator.analytics.track(.cardPresentOnboardingLearnMoreTapped)
        guard let viewController = viewController else {
            return
        }
        WebviewHelper.launch(Constants.learnMoreURL.asURL(), with: viewController)
    }
}

private extension CardPresentModalPreparingLocalReader {
    enum Constants {
        static let learnMoreURL = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Preparing built-in reader",
            comment: "Title label for modal dialog that appears when preparing the built-in reader"
        )

        static let instruction = NSLocalizedString(
            "Please wait",
            comment: "Label within the modal dialog that appears when searching the built-in reader"
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
            "%1$@ about In\u{2011}Person Payments",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     \u{2011} is a special character that acts as nonbreaking hyphen for "-" in the "In-Person" string.
                     %1$@ is a placeholder that always replaced with \"Learn more\" string,
                     which should be translated separately and considered part of this sentence.
                     """
        )
    }
}
