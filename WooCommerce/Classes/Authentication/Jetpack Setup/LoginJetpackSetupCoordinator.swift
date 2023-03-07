import UIKit
import Yosemite
import WordPressAuthenticator

/// Coordinates navigation for the Jetpack setup flow during login.
final class LoginJetpackSetupCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private let connectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics
    private let authentication: Authentication
    private var storePickerCoordinator: StorePickerCoordinator?

    init(siteURL: String,
         connectionOnly: Bool,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         authentication: Authentication = ServiceLocator.authenticationManager) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
        self.authentication = authentication
    }

    func start() {
        let siteCredentialUI = SiteCredentialLoginHostingViewController(
            siteURL: siteURL,
            connectionOnly: connectionOnly,
            onLoginSuccess: { [weak self] in
                self?.showSetupSteps()
        })
        navigationController.present(UINavigationController(rootViewController: siteCredentialUI), animated: true)
    }
}

// MARK: Private helpers
//
private extension LoginJetpackSetupCoordinator {
    func showSetupSteps() {
        let setupUI = JetpackSetupHostingController(siteURL: siteURL, connectionOnly: connectionOnly, onStoreNavigation: { [weak self] connectedEmail in
            guard let self, let email = connectedEmail else { return }
            if email != self.stores.sessionManager.defaultAccount?.email {
                // if the user authorized Jetpack with a different account, support them to log in with that account.
                self.analytics.track(.loginJetpackSetupAuthorizedUsingDifferentWPCOMAccount)
                self.showVerifyWPComAccount(email: email)
            } else {
                self.showStorePickerForLogin()
            }

        })
        guard let contentNavigationController = navigationController.presentedViewController as? UINavigationController else {
            // this is not likely to happen but handling this for safety
            return navigationController.present(UINavigationController(rootViewController: setupUI), animated: true)
        }
        contentNavigationController.setViewControllers([setupUI], animated: true)
    }

    func showVerifyWPComAccount(email: String) {
        WordPressAuthenticator.showVerifyEmailForWPCom(
            from: navigationController.presentedViewController ?? navigationController,
            xmlrpc: "",
            connectedEmail: email,
            siteURL: siteURL
        )
    }

    func showStorePickerForLogin() {
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .login)

        // Tries re-syncing to get an updated store list
        stores.synchronizeEntities { [weak self] in
            guard let self = self else { return }
            let matcher = ULAccountMatcher()
            matcher.refreshStoredSites()
            guard let matchedSite = matcher.matchedSite(originalURL: self.siteURL) else {
                DDLogWarn("⚠️ Could not find \(self.siteURL) connected to the account")
                let topViewController = self.navigationController.presentedViewController ?? self.navigationController
                return self.showNoMatchedSiteAlert(from: topViewController)
            }

            // dismiss the setup view
            self.navigationController.dismiss(animated: true)

            // open the store picker if the matched site doesn't have Woo so the user can install it.
            guard matchedSite.isWooCommerceActive else {
                self.storePickerCoordinator?.start()
                return
            }

            // navigate the user to the home screen.
            self.storePickerCoordinator?.didSelectStore(with: matchedSite.siteID, onCompletion: {})
        }
    }

    func showNoMatchedSiteAlert(from viewController: UIViewController) {
        analytics.track(.loginJetpackNoMatchedSiteErrorViewed)
        let alert = UIAlertController(title: nil, message: Localization.noMatchSiteAlertTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localization.tryAgain, style: .default, handler: { [weak self] _ in
            guard let self else { return }

            self.analytics.track(.loginJetpackNoMatchedSiteErrorTryAgainButtonTapped)
            self.showStorePickerForLogin()
        }))
        alert.addAction(UIAlertAction(title: Localization.contactSupport, style: .default, handler: { [weak self] _ in
            guard let self else { return }

            self.analytics.track(.loginJetpackNoMatchedSiteErrorContactSupportButtonTapped)
            self.authentication.presentSupport(from: viewController, screen: .storePicker)
        }))
        viewController.present(alert, animated: true)
    }
}

private extension LoginJetpackSetupCoordinator {
    enum Localization {
        static let noMatchSiteAlertTitle = NSLocalizedString(
            "We cannot load the store at the moment.",
            comment: "Error message displayed when there is no store matching the site URL " +
            "that is associated with the user's account"
        )
        static let tryAgain = NSLocalizedString("Try Again", comment: "Title of the button to attempt loading the store again after Jetpack setup")
        static let contactSupport = NSLocalizedString(
            "Contact Support",
            comment: "Title of the button to contact support for help accessing a store after Jetpack setup"
        )
    }
}
