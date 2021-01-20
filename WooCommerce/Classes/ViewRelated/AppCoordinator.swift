import Combine
import UIKit
import Yosemite

/// Coordinates app navigation based on authentication state: tab bar UI is shown when the app is logged in, and authentication UI is shown
/// when the app is logged out.
///
final class AppCoordinator {
    let tabBarController: MainTabBarController

    private let window: UIWindow
    private let stores: StoresManager
    private let authenticationManager: Authentication

    private var storePickerCoordinator: StorePickerCoordinator?
    private var cancellable: AnyCancellable?
    private var isLoggedIn: Bool = false

    init(window: UIWindow,
         stores: StoresManager = ServiceLocator.stores,
         authenticationManager: Authentication = ServiceLocator.authenticationManager) {
        self.window = window
        self.tabBarController = {
            let storyboard = UIStoryboard(name: "Main", bundle: nil) // Main is the name of storyboard
            guard let tabBarController = storyboard.instantiateInitialViewController() as? MainTabBarController else {
                fatalError("Cannot load main tab bar controller from Storyboard")
            }
            return tabBarController
        }()
        self.stores = stores
        self.authenticationManager = authenticationManager
    }

    func start() {
        cancellable = Publishers.CombineLatest(stores.isLoggedInPublisher, stores.needsDefaultStorePublisher)
            .sink {  [weak self] isLoggedIn, needsDefaultStore in
                guard let self = self else { return }

                if isLoggedIn == false {
                    // When logging out, we only want to display the authenticator when `isLoggedIn` is `false` and `needsDefaultStore` is `true`.
                    if needsDefaultStore {
                        self.displayAuthenticator()
                    }
                } else {
                    if needsDefaultStore {
                        self.displayStorePicker()
                    } else {
                        self.window.rootViewController = self.tabBarController
                    }
                }
                self.isLoggedIn = isLoggedIn
            }
    }
}

private extension AppCoordinator {
    /// Displays the WordPress.com Authentication UI.
    ///
    func displayAuthenticator() {
        let authenticationUI = authenticationManager.authenticationUI()
        window.rootViewController = authenticationUI
        ServiceLocator.analytics.track(.openedLogin)

        UIView.transition(with: window, duration: Constants.animationDuration, options: .transitionCrossDissolve, animations: {}, completion: { [weak self] _ in
            guard let self = self else { return }
            self.tabBarController.removeViewControllers()
        })
    }

    /// If the app is authenticated but there is no default store ID on launch: Let's display the Store Picker.
    ///
    func displayStorePicker() {
        // Store picker is only displayed by `AppCoordinator` on launch, when the window's root is uninitialized.
        // In other cases when the app is authenticated but there is no default store ID, the store picker is shown by authentication UI.
        guard window.rootViewController == nil else {
            return
        }

        DDLogInfo("💬 Authenticated user does not have a Woo store selected — launching store picker.")
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .standard)
        storePickerCoordinator?.start()
        storePickerCoordinator?.onDismiss = { [weak self] in
            guard let self = self else { return }
            if self.isLoggedIn == false {
                self.displayAuthenticator()
            }
        }
    }
}

private extension AppCoordinator {
    enum Constants {
        static let animationDuration = TimeInterval(0.3)
    }
}
