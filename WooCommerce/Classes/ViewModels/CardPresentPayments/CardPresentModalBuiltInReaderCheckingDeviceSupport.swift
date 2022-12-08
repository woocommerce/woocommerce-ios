import UIKit

/// Modal presented when we are scanning for a reader to connect to
///
final class CardPresentModalBuiltInReaderCheckingDeviceSupport: CardPresentPaymentsModalViewModel {
    /// Called when cancel button is tapped
    private let cancelAction: () -> Void

    let textMode: PaymentsModalTextMode = .fullInfo
    let actionsMode: PaymentsModalActionsMode = .secondaryActionAndAuxiliaryButton

    let topTitle: String = Localization.title

    var topSubtitle: String?

    let image: UIImage = .preparingBuiltInReader.resizedImage(
        CGSize(width: 300, height: 227),
        interpolationQuality: .default)

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

    let bottomTitle: String? = nil

    var bottomSubtitle: String? = Localization.instruction

    var accessibilityLabel: String? {
        return topTitle + Localization.instruction
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

private extension CardPresentModalBuiltInReaderCheckingDeviceSupport {
    enum Constants {
        static let learnMoreURL = WooConstants.URLs.inPersonPaymentsLearnMoreWCPay
    }

    enum Localization {
        static let title = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.title",
            value: "Checking device",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.instruction",
            value: "Please wait while we check that your device is ready for Tap to Pay on iPhone.",
            comment: "Label within the modal dialog that appears when checking the built in card reader"
        )

        static let cancel = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.cancelButton",
            value: "Cancel",
            comment: "Label for a cancel button"
        )

        static let learnMoreLink = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.learnMore.link",
            value: "Learn more",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     This is the link to the website, and forms part of a longer sentence which it should be considered a part of.
                     """
        )

        static let learnMoreText = NSLocalizedString(
            "cardPresent.builtIn.modalCheckingDeviceSupport.learnMore.text",
            value: "%1$@ about In‑Person Payments",
            comment: """
                     A label prompting users to learn more about In-Person Payments.
                     The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                     If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it.
                     %1$@ is a placeholder that always replaced with \"Learn more\" string,
                     which should be translated separately and considered part of this sentence.
                     """
        )
    }
}
