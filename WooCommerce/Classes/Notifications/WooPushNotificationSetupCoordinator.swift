import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private var loginCoordinator: WPComLoginCoordinator?

    init(rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores) {
        self.rootViewController = rootViewController
        self.loginCoordinator = {
            if stores.sessionManager.defaultSite?.isJetpackConnected == true {
                return nil // no need to connect WPCom
            }
            return WPComLoginCoordinator(
                title: Localization.flowTitle,
                flow: .notificationSetup,
                navigationController: UINavigationController(),
                completionHandler: { credentials in
                    // TODO: use credentials for Jetpack setup flow.
                    // Consider reusing JetpackSetupViewModel
                    // Also check JetpackSetupHostingController for more details on what the credentials are for.
                    DDLogDebug("📱 Authentication complete, proceed with Jetpack connection")
            })
        }()
    }

    func start() {
        guard let loginCoordinator else {
            // TODO: start plugin check
            DDLogDebug("📱 Site is connected to Jetpack, now checking plugin version...")
            return
        }
        rootViewController.dismiss(animated: true) {
            self.rootViewController.present(loginCoordinator.navigationController, animated: true)
            loginCoordinator.startWithoutEmail()
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
