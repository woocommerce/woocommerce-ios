import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
@MainActor
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private let stores: StoresManager
    private var loginCoordinator: WPComLoginCoordinator?
    private var wpcomCredentials: Credentials?

    init(rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores) {
        self.rootViewController = rootViewController
        self.stores = stores
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
                    self?.wpcomCredentials = credentials
                    DispatchQueue.main.async {
                        self?.showConnectionSetup()
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
        wpcomCredentials = Credentials(authToken: authToken)
        showConnectionSetup()
        return true
    }
}

private extension WooPushNotificationSetupCoordinator {
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
    }

    func showConnectionSetup() {
        let storeName = stores.sessionManager.defaultSite?.name ?? stores.sessionManager.defaultSite?.url ?? ""
        let navigationController = WooNavigationController()
        let viewModel = WPComConnectionSetupViewModel(storeName: storeName, onDismiss: { [weak navigationController] in
            navigationController?.dismiss(animated: true)
        })
        guard let site = stores.sessionManager.defaultSite else {
            DDLogError("⛔️ WPCom connection setup: No default site available")
            return
        }

        let storeName = site.name ?? site.url
        let siteURL = site.url

        // Create services
        let connectionService: WPComConnectionServiceProtocol
        if let credentials = wpcomCredentials {
            connectionService = WPComConnectionService(siteURL: siteURL, wpcomCredentials: credentials, stores: stores)
        } else {
            // Site is already Jetpack-connected, use a no-op connection service
            connectionService = AlreadyConnectedService()
        }

        let pluginChecker = PluginCompatibilityChecker(siteID: site.siteID, stores: stores)

        // Create handler
        let handler = WPComConnectionSetupHandler(
            connectionService: connectionService,
            pluginChecker: pluginChecker
        )

        let navigationController = WooNavigationController()

        let viewModel = WPComConnectionSetupViewModel(
            storeName: storeName,
            handler: handler,
            onDismiss: { [weak self] in
                navigationController?.dismiss(animated: true)
            },
            onGoToStore: { [weak self] in
                self?.goToStore()
            },
            onUpdatePlugin: { [weak self] in
                self?.openPluginUpdateURL()
            }
        )

        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel)
        navigationController.viewControllers = [connectionSetupController]

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

    func goToStore() {
        // Dismiss connection setup modal and navigate to store
        rootViewController.dismiss(animated: true) { [weak self] in
            // Navigate to the store dashboard using notification
            MainTabBarController.switchToMyStoreTab()
            self?.cleanUp()
        }
    }

    func openPluginUpdateURL() {
        guard let site = stores.sessionManager.defaultSite else { return }

        // Construct the plugin update URL for the WooCommerce plugin
        let pluginUpdateURL = site.url + "/wp-admin/plugins.php?s=woocommerce&plugin_status=upgrade"
        guard let url = URL(string: pluginUpdateURL) else { return }

        UIApplication.shared.open(url)
    }

    func cleanUp() {
        wpcomCredentials = nil
        loginCoordinator = nil
    }
}

/// A no-op connection service for sites that are already Jetpack-connected.
/// Used when the site doesn't need WPCom connection but we still need to check plugin compatibility.
private struct AlreadyConnectedService: WPComConnectionServiceProtocol {
    func connect() async throws {
        // No-op: Site is already connected
        DDLogDebug("📱 WPCom connection: Site already Jetpack-connected, skipping connection step")
    }
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
