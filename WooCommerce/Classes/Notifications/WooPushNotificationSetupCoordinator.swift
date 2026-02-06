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
        let handler = WPComConnectionSetupHandler()
        let viewModel = WPComConnectionSetupViewModel(
            storeName: storeName,
            handler: handler,
            onDismiss: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onGoToStore: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onUpdatePlugin: {
                // TODO: Implement plugin update flow in follow-up PR
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
