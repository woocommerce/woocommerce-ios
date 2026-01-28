import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
final class WooPushNotificationSetupCoordinator: Coordinator {
    let navigationController: UINavigationController

    private var loginCoordinator: WPComLoginCoordinator?

    init(navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores) {
        self.navigationController = navigationController
        self.loginCoordinator = {
            if stores.sessionManager.defaultSite?.isJetpackConnected == true {
                return nil // no need to connect WPCom
            }
            return WPComLoginCoordinator(
                title: Localization.flowTitle,
                flow: .notificationSetup,
                navigationController: navigationController,
                completionHandler: {
                // TODO
            })
        }()
    }

    func start() {
        guard let loginCoordinator else {
            // TODO: start plugin check
            DDLogDebug("📱 Site is connected to Jetpack, now checking plugin version...")
            return
        }
        loginCoordinator.startWithoutEmail()
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
