import UIKit
import SwiftUI
import struct Yosemite.Site

/// Coordinates navigation of the payments setup action from store onboarding.
final class StoreOnboardingPaymentsSetupCoordinator: Coordinator {
    enum Task {
        case wcPay
        case payments
    }

    let navigationController: UINavigationController

    private let task: Task
    private let site: Site

    init(task: Task, site: Site, navigationController: UINavigationController) {
        self.task = task
        self.site = site
        self.navigationController = navigationController
    }

    func start() {
        // Navigation controller for the payments setup flow.
        let modalNavigationController = WooNavigationController()
        showSetupView(in: modalNavigationController)
        navigationController.present(modalNavigationController, animated: true)
    }
}

private extension StoreOnboardingPaymentsSetupCoordinator {
    func showSetupView(in navigationController: UINavigationController) {
        let setupController = StoreOnboardingPaymentsSetupHostingController(task: task) { [weak self] in
            self?.showWebview(in: navigationController)
        } onDismiss: {
            navigationController.dismiss(animated: true)
        }
        navigationController.pushViewController(setupController, animated: false)
    }

    func showWebview(in navigationController: UINavigationController) {
        let urlString: String
        let title: String
        switch task {
        case .wcPay:
            urlString = URLs.wcPay(site: site)
            title = Localization.wcPayWebviewTitle
        case .payments:
            urlString = URLs.payments(site: site)
            title = Localization.paymentsWebviewTitle
        }

        guard let url = URL(string: urlString) else {
            return assertionFailure("Invalid URL for onboarding payments setup: \(urlString)")
        }

        let webViewModel = WPAdminWebViewModel(title: title, initialURL: url)
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        webViewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(dismissWebview))
        navigationController.show(webViewController, sender: navigationController)
    }

    @objc func dismissWebview() {
        navigationController.dismiss(animated: true)
    }
}

private extension StoreOnboardingPaymentsSetupCoordinator {
    enum Localization {
        static let wcPayWebviewTitle = NSLocalizedString(
            "WooCommerce Payments",
            comment: "Title of the webview for WCPay setup from onboarding."
        )
        static let paymentsWebviewTitle = NSLocalizedString(
            "Payments",
            comment: "Title of the webview for payments setup from onboarding."
        )
    }

    enum URLs {
        static func wcPay(site: Site) -> String {
            "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-settings&tab=checkout"
        }

        static func payments(site: Site) -> String {
            "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-admin&task=payments"
        }
    }
}
