import UIKit
import Yosemite

/// Coordinates navigation for the Jetpack setup flow during login.
final class LoginJetpackSetupCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let siteURL: String
    /// Whether Jetpack is installed and activated and only connection needs to be handled.
    private let connectionOnly: Bool
    private let stores: StoresManager
    private let analytics: Analytics
    private var storePickerCoordinator: StorePickerCoordinator?

    init(siteURL: String,
         connectionOnly: Bool,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteURL = siteURL
        self.connectionOnly = connectionOnly
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func start() {
        let siteCredentialUI = SiteCredentialLoginHostingViewController(siteURL: siteURL, connectionOnly: connectionOnly, onLoginSuccess: showSetupSteps)
        navigationController.present(UINavigationController(rootViewController: siteCredentialUI), animated: true)
    }
}

// MARK: Private helpers
//
private extension LoginJetpackSetupCoordinator {
    func showSetupSteps() {
        let setupUI = LoginJetpackSetupHostingController(siteURL: siteURL, connectionOnly: connectionOnly, onStoreNavigation: { [weak self] in
            guard let self else { return }
            self.showStorePickerForLogin()
        })
        guard let contentNavigationController = navigationController.presentedViewController as? UINavigationController else {
            // this is not likely to happen but handling this for safety
            return navigationController.present(UINavigationController(rootViewController: setupUI), animated: true)
        }
        contentNavigationController.setViewControllers([setupUI], animated: true)
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
                return
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
}
