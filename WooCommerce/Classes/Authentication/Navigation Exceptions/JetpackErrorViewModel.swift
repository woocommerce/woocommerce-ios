import UIKit
import SafariServices
import WordPressAuthenticator
import WordPressUI


/// Configuration and actions for an ULErrorViewController, modelling
/// an error when Jetpack is not installed or is not connected
struct JetpackErrorViewModel: ULErrorViewModel {
    private let siteURL: String
    private let analytics: Analytics
    private let jetpackSetupCompletionHandler: () -> Void

    init(siteURL: String?, analytics: Analytics = ServiceLocator.analytics, onJetpackSetupCompletion: @escaping () -> Void) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.analytics = analytics
        self.jetpackSetupCompletionHandler = onJetpackSetupCompletion
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

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = Localization.whatIsJetpack

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        showJetpackSetupScreen(in: viewController)
        analytics.track(.loginJetpackRequiredViewInstructionsButtonTapped)
    }

    private func showJetpackSetupScreen(in viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }

        let connectionController = JetpackSetupWebViewController(siteURL: siteURL) {
            self.jetpackSetupCompletionHandler()
        }
        viewController.navigationController?.show(connectionController, sender: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToRoot()
        refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeWhatIsJetpackAlertController(analytics: analytics)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)

        analytics.track(.loginWhatIsJetpackHelpScreenViewed)
    }

    func viewDidLoad() {
        analytics.track(.loginJetpackRequiredScreenViewed)
    }
}


// MARK: - Private data structures
private extension JetpackErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("To use this app for %@ you'll need to have the Jetpack plugin installed and connected on your store.",
                                                    comment: "Message explaining that Jetpack needs to be installed for a particular site. "
                                                        + "Reads like 'To use this ap for awebsite.com you'll need to have...")

        static let whatIsJetpack = NSLocalizedString("What is Jetpack?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let primaryButtonTitle = NSLocalizedString("Install Jetpack",
                                                          comment: "Action button for installing Jetpack."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a site address that does not have a valid Jetpack installation."
                                                + "The error would read: to use this app for your site you'll need...")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"
    }
}
