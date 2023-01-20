import UIKit
import WordPressAuthenticator

/// Configuration and actions for an ULErrorViewController,
/// modeling an error when application password is disabled.
///
struct ApplicationPasswordDisabledViewModel: ULErrorViewModel {
    init(siteURL: String) {
        self.siteURL = siteURL
    }

    let siteURL: String
    let image: UIImage = .errorImage // TODO: update this if needed

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                 attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = false
    let auxiliaryButtonTitle = Localization.auxiliaryButtonTitle

    let primaryButtonTitle = Localization.primaryButtonTitle
    let isPrimaryButtonHidden = false

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    func viewDidLoad(_ viewController: UIViewController?) {
        // TODO: add tracks if necessary
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let viewController else {
            return
        }
        WordPressAuthenticator.showLoginForJustWPCom(from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        ServiceLocator.stores.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        guard let viewController else {
            return
        }
        WebviewHelper.launch(Constants.applicationPasswordLink, with: viewController)
    }
}

private extension ApplicationPasswordDisabledViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString(
            "It seems that your site %@ has Application Password disabled. Please enable it to use the WooCommerce app.",
            comment: "An error message displayed when the user tries to log in to the app with site credentials but has application password disabled. " +
            "Reads like: It seems that your site google.com has Application Password disabled. " +
            "Please enable it to use the WooCommerce app."
        )
        static let secondaryButtonTitle = NSLocalizedString(
            "Log In With Another Account",
            comment: "Action button that will restart the login flow."
            + "Presented when the user tries to log in to the app with site credentials but has application password disabled."
        )
        static let auxiliaryButtonTitle = NSLocalizedString(
            "What is Application Password?",
            comment: "Button that will navigate to a web page explaining Application Password"
        )
        static let primaryButtonTitle = NSLocalizedString(
            "Log in with WordPress.com",
            comment: "Button that will navigate to the authentication flow with WP.com"
        )
    }
    enum Constants {
        static let applicationPasswordLink = "https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/"
    }
}
