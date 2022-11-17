import UIKit
import Yosemite

/// Coordinates navigation for the Jetpack setup flow during login.
final class LoginJetpackSetupCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let stores: StoresManager
    private let analytics: Analytics

    init(navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.navigationController = navigationController
        self.stores = stores
        self.analytics = analytics
    }

    func start() {
        // TODO
    }
}
