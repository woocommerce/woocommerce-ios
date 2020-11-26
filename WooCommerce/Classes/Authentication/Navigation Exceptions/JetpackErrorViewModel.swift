import UIKit
import SafariServices
import WordPressAuthenticator

struct JetpackErrorViewModel: ULErrorViewModel {
    private let siteURL: String

    init(siteURL: String) {
        self.siteURL = siteURL
    }

    // MARK: - Queries
    let image: UIImage = .loginNoJetpackError

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL,
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonVisible = true

    let auxiliaryButtonTitle = Localization.whatIsJetpack

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Commands
    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Strings.instructionsURLString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        viewController?.present(safariViewController, animated: true)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToEnterSite()
        refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        guard let url = URL(string: Strings.whatsJetpackURLString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        viewController?.present(safariViewController, animated: true)
    }
}

private extension JetpackErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("To use this app for %@ you'll need to have the Jetpack plugin installed and connected on your store.",
                                                    comment: "Message explaining that Jetpack needs to be installed for a particular site. "
                                                        + "Reads like 'To use this ap for awebsite.com you'll need to have...")

        static let whatIsJetpack = NSLocalizedString("What is Jetpack",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let primaryButtonTitle = NSLocalizedString("See Instructions",
                                                          comment: "Action button linking to instructions for installing Jetpack."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Refresh After Install",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"

        static let whatsJetpackURLString = "https://jetpack.com/about/"
    }
}
