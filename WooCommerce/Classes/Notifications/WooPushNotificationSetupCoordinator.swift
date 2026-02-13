import SwiftUI
import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
@MainActor
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private let stores: StoresManager
    private var loginCoordinator: WPComLoginCoordinator?

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

    func showPluginUpdateSetup() {
        let (navigationController, _) = makeConnectionSetupStack(credentials: nil, pluginOutdated: true)

        // Dismiss benefits modal, then present setup view, then auto-open web view
        let presentAndAutoOpen: (UIViewController) -> Void = { [stores] presenter in
            presenter.present(navigationController, animated: true) {
                guard let site = stores.sessionManager.defaultSite,
                      let url = URL(string: site.pluginsURL) else { return }
                let webView = AuthenticatableWebView(url: url, title: Localization.updateWooCommerce)
                let webViewController = UIHostingController(rootView: webView)
                webViewController.modalPresentationStyle = .formSheet
                navigationController.present(webViewController, animated: true)
            }
        }

        if let presenter = rootViewController.presentingViewController {
            rootViewController.dismiss(animated: true) {
                presentAndAutoOpen(presenter)
            }
        } else {
            presentAndAutoOpen(rootViewController)
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
    /// Returns the navigation controller and the view model for further configuration.
    func makeConnectionSetupStack(credentials: Credentials? = nil,
                                  pluginOutdated: Bool = false) -> (WooNavigationController, WPComConnectionSetupViewModel) {
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
            onGoToStore: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onUpdatePlugin: { [weak navigationController] in
                guard let url = URL(string: site.pluginsURL) else { return }
                let webView = AuthenticatableWebView(url: url, title: Localization.updateWooCommerce)
                let webViewController = UIHostingController(rootView: webView)
                webViewController.modalPresentationStyle = .formSheet
                navigationController?.present(webViewController, animated: true)
            }
        )
        if pluginOutdated {
            viewModel.setPluginOutdatedState()
        }
        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel, credentials: credentials)
        navigationController.viewControllers = [connectionSetupController]
        return (navigationController, viewModel)
    }

    func showConnectionSetup(with credentials: Credentials? = nil) {
        let (navigationController, _) = makeConnectionSetupStack(credentials: credentials)

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
        static let updateWooCommerce = NSLocalizedString(
            "wooPushNotificationSetupCoordinator.updateWooCommerce",
            value: "Update WooCommerce",
            comment: "Title of the web view shown when the user taps 'Update plugin' to update WooCommerce"
        )
    }
}
