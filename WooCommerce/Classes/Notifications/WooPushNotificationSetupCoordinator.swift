import UIKit
import Yosemite

@MainActor
final class WooPushNotificationSetupCoordinator {
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
                return nil
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
        static let wooCommercePluginPath = "woocommerce/woocommerce.php"
        static let minimumWooCommerceVersion = "10.4.3"
    }

    func showConnectionSetup() {
        guard let site = stores.sessionManager.defaultSite else {
            DDLogError("⛔️ WPCom connection setup: No default site available")
            return
        }

        let connectionService: WPComConnectionServiceProtocol? = wpcomCredentials.map {
            WPComConnectionService(siteURL: site.url, wpcomCredentials: $0, stores: stores)
        }

        let pluginChecker = SitePluginVersionChecker(
            siteID: site.siteID,
            pluginPath: Constants.wooCommercePluginPath,
            minimumVersion: Constants.minimumWooCommerceVersion,
            stores: stores
        )

        let handler = WPComConnectionSetupHandler(
            connectionService: connectionService,
            pluginChecker: pluginChecker
        )

        let navigationController = WooNavigationController()

        let viewModel = makeConnectionSetupViewModel(
            site: site,
            handler: handler,
            navigationController: navigationController
        )

        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel)
        navigationController.viewControllers = [connectionSetupController]

        if let loginNav = loginCoordinator?.navigationController,
           let presenter = loginNav.presentingViewController {
            loginNav.dismiss(animated: true) {
                presenter.present(navigationController, animated: true)
            }
        } else if let presenter = rootViewController.presentingViewController {
            rootViewController.dismiss(animated: true) {
                presenter.present(navigationController, animated: true)
            }
        }
    }

    func makeConnectionSetupViewModel(
        site: Site,
        handler: WPComConnectionSetupHandlerProtocol,
        navigationController: UINavigationController
    ) -> WPComConnectionSetupViewModel {
        WPComConnectionSetupViewModel(
            storeName: site.name,
            handler: handler,
            onDismiss: { [navigationController] in
                navigationController.dismiss(animated: true)
            },
            onGoToStore: { [weak self] in
                self?.goToStore()
            },
            onUpdatePlugin: { [weak self] in
                self?.openPluginUpdateURL()
            }
        )
    }

    func goToStore() {
        rootViewController.dismiss(animated: true) { [weak self] in
            MainTabBarController.switchToMyStoreTab()
            self?.cleanUp()
        }
    }

    func openPluginUpdateURL() {
        guard let site = stores.sessionManager.defaultSite else { return }

        let pluginUpdateURL = site.url + "/wp-admin/plugins.php?s=woocommerce&plugin_status=upgrade"
        guard let url = URL(string: pluginUpdateURL) else { return }

        UIApplication.shared.open(url)
    }

    func cleanUp() {
        wpcomCredentials = nil
        loginCoordinator = nil
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
