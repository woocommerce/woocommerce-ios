import UIKit
import SafariServices
import WordPressAuthenticator
import WordPressUI


/// Configuration and actions for an ULErrorViewController, modelling
/// an error when the site is not a WordPress site
struct NotWPErrorViewModel: ULErrorViewModel {
    private let siteURL: String

    init(siteURL: String) {
        self.siteURL = siteURL
    }

    // MARK: - Data and configuration
    let image: UIImage = .loginNoJetpackError

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = true

    let auxiliaryButtonTitle = ""

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Strings.instructionsURLString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        viewController?.present(safariViewController, animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //let refreshCommand = NavigateToRoot()
        //refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // NO-OP
    }
}


// MARK: - Private data structures
private extension NotWPErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("The website %@ is not a WordPress site. For us to connect to it, the site must have WordPress installed.",
                                                    comment: "Message explaining that a site is not a WordPress site. "
                                                        + "Reads like 'The website awebsite.com you'll is not a WordPress site...")

        static let primaryButtonTitle = NSLocalizedString("Enter Another Site",
                                                          comment: "Action button linking to instructions for enter another site."
                                                          + "Presented when logging in with a site address that is not a WordPress site")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"
    }
}
