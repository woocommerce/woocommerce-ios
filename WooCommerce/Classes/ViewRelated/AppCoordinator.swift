import UIKit

/// Coordinates app navigation based on authentication state: tab bar UI is shown when the app is logged in, and authentication UI is shown
/// when the app is logged out.
///
final class AppCoordinator {
    private let tabBarController: MainTabBarController
    private let stores: StoresManager
    private let authenticationManager: Authentication

    private var storePickerCoordinator: StorePickerCoordinator?
    private var cancellable: ObservationToken?
    private var isLoggedIn: Bool = false

    init(tabBarController: MainTabBarController,
         stores: StoresManager = ServiceLocator.stores,
         authenticationManager: Authentication = ServiceLocator.authenticationManager) {
        self.tabBarController = tabBarController
        self.stores = stores
        self.authenticationManager = authenticationManager
    }

    func start() {
        cancellable = stores.isLoggedIn.subscribe { [weak self] isLoggedIn in
            guard let self = self else { return }

            if isLoggedIn == false {
                let animated = self.isLoggedIn == true
                self.displayAuthenticator(animated: animated)
            } else if self.stores.needsDefaultStore {
                self.displayStorePicker()
            }

            self.isLoggedIn = isLoggedIn
        }
    }
}

private extension AppCoordinator {
    /// Displays the WordPress.com Authentication UI.
    ///
    func displayAuthenticator(animated: Bool) {
        authenticationManager.displayAuthentication(from: tabBarController, animated: animated) { [weak self] in
            guard let self = self else { return }
            self.tabBarController.removeViewControllers()
        }
    }

    /// Whenever the app is authenticated but there is no Default StoreID: Let's display the Store Picker.
    ///
    func displayStorePicker() {
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            DDLogError("⛔️ Unable to locate navigationController in order to launch the store picker.")
            return
        }

        DDLogInfo("💬 Authenticated user does not have a Woo store selected — launching store picker.")
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .standard)
        storePickerCoordinator?.start()
        storePickerCoordinator?.onDismiss = { [weak self] in
            self?.displayAuthenticator(animated: false)
        }
    }
}
