import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
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
                    // TODO: use credentials for Jetpack connection flow.
                    // Consider reusing JetpackSetupViewModel
                    // Also check JetpackSetupHostingController for more details on what the credentials are for.

                    DDLogDebug("📱 Authentication complete, proceed with Jetpack connection")
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

        // TODO: start Jetpack connection flow with the retrieved authToken.
        DDLogDebug("📱 Magic link success, now proceed with Jetpack connection")
        return true
    }
}

private extension WooPushNotificationSetupCoordinator {
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
    }

    /// Returns the navigation controller to use for presenting the connection setup view.
    var currentNavigationController: UINavigationController? {
        loginCoordinator?.navigationController ?? (rootViewController as? UINavigationController)
    }

    func showConnectionSetup() {
        let storeName = stores.sessionManager.defaultSite?.name ?? stores.sessionManager.defaultSite?.url ?? ""
        let viewModel = WPComConnectionSetupViewModel(storeName: storeName, onDismiss: { [weak self] in
            self?.dismissFlow()
        })
        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel)
        currentNavigationController?.pushViewController(connectionSetupController, animated: true)
    }

    func dismissFlow() {
        currentNavigationController?.dismiss(animated: true)
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
