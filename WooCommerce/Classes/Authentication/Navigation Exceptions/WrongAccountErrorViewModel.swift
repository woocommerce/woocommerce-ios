import UIKit
import SafariServices
import WordPressUI
import Yosemite


/// Configuration and actions for an ULErrorViewController, modelling
/// an error when Jetpack is not installed or is not connected
struct WrongAccountErrorViewModel: ULAccountMismatchViewModel {
    private let siteURL: String
    private let defaultAccount: Account?
    private let storesManager: StoresManager

    init(siteURL: String?,
         sessionManager: SessionManagerProtocol =  ServiceLocator.stores.sessionManager,
         storesManager: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.defaultAccount = sessionManager.defaultAccount
        self.storesManager = storesManager
    }

    // MARK: - Data and configuration
    var userEmail: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default account")

            return ""
        }
        return account.email
    }

    var userName: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default account")

            return ""
        }

        return account.displayName
    }

    var signedInText: String {
        guard let account = defaultAccount else {
            DDLogWarn("⚠️ Present account mismatch UI for \(siteURL) without a default display account")

            return ""
        }

        return String.localizedStringWithFormat(Localization.signedInMessageFormat,
                                                account.username)
    }

    let logOutTitle: String = Localization.wrongAccountMessage

    let logOutButtonTitle: String = Localization.logOutButtonTitle

    let image: UIImage = .errorImage

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

    let auxiliaryButtonTitle = Localization.findYourConnectedEmail

    let primaryButtonTitle = Localization.primaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        let storePicker = StorePickerViewController()
        storePicker.configuration = .listStores

        navigationController.pushViewController(storePicker, animated: true)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }

    func didTapLogOutButton(in viewController: UIViewController?) {
        // Log out and pop
        storesManager.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
}


// MARK: - Private data structures
private extension WrongAccountErrorViewModel {
    enum Localization {
        static let signedInMessageFormat = NSLocalizedString("Signed in as @%1$@",
                                                             comment: "Message describing the account a user has signed in to."
                                                                + "Reads as: Signed is as @{username}"
                                                                + "Parameters: %1$@ - user name")

        static let errorMessage = NSLocalizedString("It looks like %@ is connected to a different account.",
                                                    comment: "Message explaining that the site entered and the acount logged into do not match. "
                                                        + "Reads like 'It looks like awebsite.com is connected to a different account")

        static let findYourConnectedEmail = NSLocalizedString("Find your connected email",
                                                     comment: "Button linking to webview explaining how to find your connected email"
                                                        + "Presented when logging in with a store address that does not match the account entered")

        static let logOutButtonTitle = NSLocalizedString("Log Out",
                                                          comment: "Action button triggering a Log Out."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let primaryButtonTitle = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores."
                                                          + "Presented when logging in with a store address that does not match the account entered")

        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a store address that does not match the account entered.")

        static let wrongAccountMessage = NSLocalizedString("Wrong account?",
                                                           comment: "Prompt asking users if the logged in to the wrong account."
                                                               + "Presented when logging in with a store address that does not match the account entered.")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"
    }
}
