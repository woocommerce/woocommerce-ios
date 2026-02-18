import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
@MainActor
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private let stores: StoresManager
    private let onSetupCompleted: (() -> Void)?
    private var loginCoordinator: WPComLoginCoordinator?

    init(rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         onSetupCompleted: (() -> Void)? = nil) {
        self.rootViewController = rootViewController
        self.stores = stores
        self.onSetupCompleted = onSetupCompleted
        self.loginCoordinator = {
            if stores.sessionManager.defaultSite?.isJetpackConnected == true {
                return nil // no need to connect WPCom
            }
            return WPComLoginCoordinator(
                title: Localization.flowTitle,
                flow: .notificationSetup,
                navigationController: UINavigationController(),
                completionHandler: { [weak self] credentials in
                    DDLogDebug("📱 Authentication complete, proceed with Jetpack connection")
                    DispatchQueue.main.async {
                        self?.showConnectionSetup(with: credentials)
                    }
            })
        }()
    }

    func start() {
        guard let loginCoordinator else {
            DDLogDebug("📱 Site is connected to Jetpack, now checking plugin version...")
            showConnectionSetup()
            return
        }

        // Capture the presenting view controller before dismissing
        let presentingVC = rootViewController.presentingViewController
        rootViewController.dismiss(animated: true) {
            presentingVC?.present(loginCoordinator.navigationController, animated: true)
            loginCoordinator.startWithoutEmail()
        }
    }

    func showPluginUpdateSetup(pluginVersion: String = "") {
        let navigationController = makeConnectionSetupStack(credentials: nil, pluginOutdatedVersion: pluginVersion)

        if let presenter = rootViewController.presentingViewController {
            rootViewController.dismiss(animated: true) {
                presenter.present(navigationController, animated: true)
            }
        } else {
            rootViewController.present(navigationController, animated: true)
        }
    }

    func handleAuthenticationUrl(_ url: URL, dotcomAuthScheme: String = ApiCredentials.dotcomAuthScheme) -> Bool {
        let expectedPrefix = dotcomAuthScheme + "://" + Constants.magicLinkUrlHostname
        guard url.absoluteString.hasPrefix(expectedPrefix) else {
            return false
        }

        guard let queryDictionary = url.query?.dictionaryFromQueryString() else {
            DDLogError("⛔️ Magic link error: we couldn't retrieve the query dictionary from the sign-in URL.")
            return false
        }

        guard let authToken = queryDictionary.string(forKey: "token") else {
            DDLogError("⛔️ Magic link error: we couldn't retrieve the authentication token from the sign-in URL.")
            return false
        }

        DDLogDebug("📱 Magic link success, now proceed with Jetpack connection")
        showConnectionSetup(with: Credentials(authToken: authToken))
        return true
    }
}

private extension WooPushNotificationSetupCoordinator {
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
    }

    /// Creates the connection setup navigation stack with a handler, view model, and hosting controller.
    func makeConnectionSetupStack(credentials: Credentials? = nil,
                                  pluginOutdatedVersion: String? = nil) -> WooNavigationController {
        guard let site = stores.sessionManager.defaultSite else {
            fatalError("❌ No default site found for Woo push notification setup!")
        }
        let navigationController = WooNavigationController()
        let handler = WPComConnectionSetupHandler(
            siteID: site.siteID,
            siteURL: site.url,
            credentials: credentials
        )
        let viewModel = WPComConnectionSetupViewModel(
            storeName: site.name,
            handler: handler,
            onDismiss: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onGoToStore: { [weak navigationController, onSetupCompleted] in
                navigationController?.dismiss(animated: true)
                onSetupCompleted?()
            },
            onUpdatePlugin: {
                // TODO: Implement plugin update flow in follow-up PR
            }
        )
        if let pluginOutdatedVersion {
            viewModel.setPluginOutdatedState(version: pluginOutdatedVersion)
        }
        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel, credentials: credentials)
        navigationController.viewControllers = [connectionSetupController]
        return navigationController
    }

    func showConnectionSetup(with credentials: Credentials? = nil) {
        let navigationController = makeConnectionSetupStack(credentials: credentials)

        // Dismiss current modal (login or benefits) and present connection setup
        if let loginNav = loginCoordinator?.navigationController,
           let presenter = loginNav.presentingViewController {
            // Login flow: dismiss login modal, then present
            loginNav.dismiss(animated: true) {
                presenter.present(navigationController, animated: true)
            }
        } else if let presenter = rootViewController.presentingViewController {
            // No login flow: dismiss benefits modal, then present
            rootViewController.dismiss(animated: true) {
                presenter.present(navigationController, animated: true)
            }
        } else {
            rootViewController.present(navigationController, animated: true)
        }
    }

}

enum WooPluginRequirements {
    static let pluginPath = "woocommerce/woocommerce.php"
    static let minimumVersion = "10.5.3" // This is for testing
}

private extension WooPushNotificationSetupCoordinator {
    enum Localization {
        static let flowTitle = NSLocalizedString(
            "wooPushNotificationSetupCoordinator.flowTitle",
            value: "Connect to WordPress.com",
            comment: "Title of the self-driven push notification setup flow"
        )
    }
}
