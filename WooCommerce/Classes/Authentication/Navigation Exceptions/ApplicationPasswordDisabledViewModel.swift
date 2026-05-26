import UIKit
import WordPressAuthenticator

/// Configuration and actions for an ULErrorViewController,
/// modeling an error when application password is disabled.
///
struct ApplicationPasswordDisabledViewModel: ULErrorViewModel {
    init(siteURL: String,
         previousViewController: UIViewController?,
         authentication: Authentication = ServiceLocator.authenticationManager) {
        self.siteURL = siteURL
        self.previousViewController = previousViewController
        self.authentication = authentication
    }

    let siteURL: String
    let authentication: Authentication
    let image: UIImage = .errorImage

    // The VC that was showing before the application password flow. This is used to navigate back without guesswork.
    let previousViewController: UIViewController?

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                 attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%1$@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = false
    let auxiliaryButtonTitle = Localization.auxiliaryButtonTitle

    let primaryButtonTitle = Localization.primaryButtonTitle
    let isPrimaryButtonHidden = false

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    func viewDidLoad(_ viewController: UIViewController?) {
    }

    // Pop to the previous VC
    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else { return }
        if let previousViewController {
            navigationController.popToViewController(previousViewController, animated: true)
        } else {
            navigationController.popViewController(animated: true)
        }
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

    var rightBarButtonItemTitle: String? {
        return Localization.helpButtonTitle
    }

    func didTapRightBarButtonItem(in viewController: UIViewController?) {
        guard let viewController else {
            return
        }
        authentication.presentSupport(from: viewController, screen: .noWooError, siteURL: URL(string: siteURL))
    }
}

private extension ApplicationPasswordDisabledViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString(
            "applicationPasswordDisabled.errorMessage",
            value: "It seems that your site %1$@ has Application Password disabled. Please enable it to use the WooCommerce app.",
            comment: "An error message displayed when the user tries to log in to the app with site credentials but has application password disabled. " +
            "Reads like: It seems that your site google.com has Application Password disabled. " +
            "Please enable it to use the WooCommerce app."
        )
        static let primaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.retry.buttonTitle",
            value: "Retry",
            comment: "Button to retry fetching application password authorization if application password is disabled"
        )
        static let secondaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.secondaryButtonTitle",
            value: "Log In With Another Account",
            comment: "Action button that will restart the login flow."
            + "Presented when the user tries to log in to the app with site credentials but has application password disabled."
        )
        static let auxiliaryButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.auxiliaryButtonTitle",
            value: "What is Application Password?",
            comment: "Button that will navigate to a web page explaining Application Password"
        )
        static let helpButtonTitle = NSLocalizedString(
            "applicationPasswordDisabled.helpButtonTitle",
            value: "Help",
            comment: "Button that will navigate to the support area"
        )
    }
    enum Constants {
        static let applicationPasswordLink = "https://make.wordpress.org/core/2020/11/05/application-passwords-integration-guide/"
    }
}
