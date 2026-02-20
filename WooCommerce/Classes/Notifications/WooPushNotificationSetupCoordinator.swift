import UIKit
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
@MainActor
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private let stores: StoresManager
    private let onSetupCompleted: (() -> Void)?

    init(rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores,
         onSetupCompleted: (() -> Void)? = nil) {
        self.rootViewController = rootViewController
        self.stores = stores
        self.onSetupCompleted = onSetupCompleted
    }

    /// Presents navigation stack with a handler, view model, and hosting controller.
    func startSetup(siteAlreadyConnected: Bool,
                    pluginOutdatedVersion: String? = nil) {
        guard let site = stores.sessionManager.defaultSite else {
            fatalError("❌ No default site found for Woo push notification setup!")
        }
        let navigationController = WooNavigationController()
        let handler = WPComConnectionSetupHandler(
            siteID: site.siteID,
            siteURL: site.url,
            siteAlreadyConnected: siteAlreadyConnected
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
        let connectionSetupController = WPComConnectionSetupHostingController(viewModel: viewModel)
        navigationController.viewControllers = [connectionSetupController]

        // Dismiss current modal and present connection setup
        if let presenter = rootViewController.presentingViewController {
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
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
    }
    enum Localization {
        static let flowTitle = NSLocalizedString(
            "wooPushNotificationSetupCoordinator.flowTitle",
            value: "Connect to WordPress.com",
            comment: "Title of the self-driven push notification setup flow"
        )
    }
}
