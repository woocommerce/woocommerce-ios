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
        let setupUI = LoginJetpackSetupHostingController(siteURL: siteURL, connectionOnly: connectionOnly)
        guard let contentNavigationController = navigationController.presentedViewController as? UINavigationController else {
            // this is not likely to happen but handling this for safety
            return navigationController.present(UINavigationController(rootViewController: setupUI), animated: true)
        }
        contentNavigationController.setViewControllers([setupUI], animated: true)
    }
}
