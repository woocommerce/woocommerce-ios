import Combine
import UIKit
import Yosemite
import class AutomatticTracks.CrashLogging

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

                // More details about the UI states: https://github.com/woocommerce/woocommerce-ios/pull/3498
                switch (isLoggedIn, needsDefaultStore) {
                case (false, true), (false, false):
                    self.displayAuthenticator()
                case (true, true):
                    self.displayStorePicker()
                case (true, false):
                    self.displayLoggedInUI()
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
        setWindowRootViewControllerAndAnimateIfNeeded(authenticationUI) { [weak self] _ in
            guard let self = self else { return }
            self.tabBarController.removeViewControllers()
        }
        ServiceLocator.analytics.track(.openedLogin)
    }

    /// Displays logged in tab bar UI.
    ///
    func displayLoggedInUI() {
        setWindowRootViewControllerAndAnimateIfNeeded(tabBarController)
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
        setWindowRootViewControllerAndAnimateIfNeeded(navigationController)
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
    func setWindowRootViewControllerAndAnimateIfNeeded(_ rootViewController: UIViewController, onCompletion: @escaping (Bool) -> Void = { _ in }) {
        // Animates window transition only if the root view controller is non-nil originally.
        let shouldAnimate = window.rootViewController != nil
        window.rootViewController = rootViewController
        if shouldAnimate {
            UIView.transition(with: window, duration: Constants.animationDuration, options: .transitionCrossDissolve, animations: {}, completion: onCompletion)
        }
    }
}

private extension AppCoordinator {
    enum Constants {
        static let animationDuration = TimeInterval(0.3)
    }
}
