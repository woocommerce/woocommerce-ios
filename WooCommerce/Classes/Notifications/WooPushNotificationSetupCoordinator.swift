import UIKit
import SwiftUI
import Yosemite

/// Coordinator for the setup of self-driven push notifications for ineligible sites
@MainActor
final class WooPushNotificationSetupCoordinator {
    // Controller to handle navigation between the auth flow and setup steps.
    let rootViewController: UIViewController

    private let stores: StoresManager

    init(rootViewController: UIViewController,
         stores: StoresManager = ServiceLocator.stores) {
        self.rootViewController = rootViewController
        self.stores = stores
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
            siteAlreadyConnected: siteAlreadyConnected,
            handler: handler,
            onDismiss: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onGoToStore: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            },
            onUpdatePlugin: { [weak navigationController, stores] onDismissed in
                guard let navigationController,
                      let site = stores.sessionManager.defaultSite,
                      let url = URL(string: site.adminURL + Constants.wooCommercePluginUpdatePath) else { return }
                let webView = AuthenticatableWebView(url: url, title: Localization.updateWooCommerce, onDismiss: onDismissed)
                let vc = UIHostingController(rootView: webView)
                vc.modalPresentationStyle = .formSheet
                navigationController.present(vc, animated: true)
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
    static let minimumVersion = "10.8.0" // This is for testing
}

private extension WooPushNotificationSetupCoordinator {
    enum Constants {
        static let magicLinkUrlHostname = "magic-login"
        static let wooCommercePluginUpdatePath = "plugin-install.php?tab=plugin-information&plugin=woocommerce"
    }
    enum Localization {
        static let flowTitle = NSLocalizedString(
            "wooPushNotificationSetupCoordinator.flowTitle",
            value: "Connect to WordPress.com",
            comment: "Title of the self-driven push notification setup flow"
        )
        static let updateWooCommerce = NSLocalizedString(
            "wooPushNotificationSetupCoordinator.updateWooCommerce",
            value: "Update WooCommerce",
            comment: "Title of the web view to update WooCommerce plugin during push notification setup"
        )
    }
}
