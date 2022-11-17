import UIKit
import Yosemite

/// Coordinates navigation for the Jetpack setup flow during login.
final class LoginJetpackSetupCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let siteURL: String
    private let stores: StoresManager
    private let analytics: Analytics

    init(siteURL: String,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteURL = siteURL
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func start() {
        let siteCredentialUI = SiteCredentialLoginHostingViewController(siteURL: siteURL)
        navigationController.present(UINavigationController(rootViewController: siteCredentialUI), animated: true)
    }
}
