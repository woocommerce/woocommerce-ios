import UIKit
import SwiftUI
import struct Yosemite.Site

/// Coordinates navigation of the store details action from store onboarding.
final class StoreOnboardingStoreDetailsCoordinator: Coordinator {

    let navigationController: UINavigationController

    private let site: Site
    private let onDismiss: (() -> Void)?

    init(site: Site,
         navigationController: UINavigationController,
         onDismiss: (() -> Void)? = nil) {
        self.site = site
        self.navigationController = navigationController
        self.onDismiss = onDismiss
    }

    func start() {
        let modalNavigationController = WooNavigationController()
        showWebview(in: modalNavigationController)
        navigationController.present(modalNavigationController, animated: true)
    }
}

private extension StoreOnboardingStoreDetailsCoordinator {
    func showWebview(in navigationController: UINavigationController) {
        let urlString = Constants.url(site: site)

        guard let url = URL(string: urlString) else {
            return assertionFailure("Invalid URL for onboarding Store details: \(urlString)")
        }

        let webViewModel = WPAdminWebViewModel(title: Localization.title, initialURL: url)
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        webViewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(dismissWebview))
        navigationController.show(webViewController, sender: navigationController)
    }

    @objc func dismissWebview() {
        onDismiss?()
        navigationController.dismiss(animated: true)
    }
}

private extension StoreOnboardingStoreDetailsCoordinator {
    enum Localization {
        static let title = NSLocalizedString(
            "Store details",
            comment: "Title of the webview for Store details task from onboarding."
        )
    }

    enum Constants {
        static func url(site: Site) -> String {
            "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-settings&tab=general&tutorial=true"
        }
    }
}
