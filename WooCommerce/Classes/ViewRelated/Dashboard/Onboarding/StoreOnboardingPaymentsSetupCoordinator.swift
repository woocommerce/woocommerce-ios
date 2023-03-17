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
        showSetupView()
    }
}

private extension StoreOnboardingPaymentsSetupCoordinator {
    func showSetupView() {
        let setupController = StoreOnboardingPaymentsSetupHostingController(task: task) { [weak self] in
            self?.showWebview()
        }
        navigationController.show(setupController, sender: navigationController)
    }

    func showWebview() {
        let urlString: String
        switch task {
        case .wcPay:
            urlString = "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-settings&tab=checkout"
        case .payments:
            urlString = "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-admin&task=payments"
        }

        guard let url = URL(string: urlString) else {
            return assertionFailure("Invalid URL for onboarding payments setup: \(urlString)")
        }

        let webViewModel = DefaultAuthenticatedWebViewModel(initialURL: url)
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        navigationController.show(webViewController, sender: navigationController)
    }
}
