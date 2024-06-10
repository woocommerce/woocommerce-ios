import UIKit
import SwiftUI
import struct Yosemite.Site
import protocol WooFoundation.Analytics

/// Coordinates navigation of the payments setup action from store onboarding.
final class StoreOnboardingPaymentsSetupCoordinator: Coordinator {
    enum Task {
        case wcPay
        case payments
    }

    let navigationController: UINavigationController

    private let task: Task
    private let site: Site
    private let analytics: Analytics
    private let onCompleted: (() -> Void)?
    private let onDismiss: (() -> Void)?

    init(task: Task,
         site: Site,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics,
         onCompleted: (() -> Void)? = nil,
         onDismiss: (() -> Void)? = nil) {
        self.task = task
        self.site = site
        self.navigationController = navigationController
        self.analytics = analytics
        self.onCompleted = onCompleted
        self.onDismiss = onDismiss
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
            self?.analytics.track(.storeOnboardingWCPayTermsContinueTapped)
            self?.showWebview(in: navigationController)
        } onDismiss: {
            navigationController.dismiss(animated: true)
        }

        if task == .wcPay {
            let instructionsController = WooPaymentsSetupInstructionsHostingController { [weak self] in
                self?.analytics.track(.storeOnboardingWCPayBeginSetupTapped)
                navigationController.pushViewController(setupController, animated: true)
            } onDismiss: {
                navigationController.dismiss(animated: true)
            }
            navigationController.pushViewController(instructionsController, animated: false)
        } else {
            navigationController.pushViewController(setupController, animated: false)
        }
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

        let webViewModel = WooPaymentSetupWebViewModel(title: title, initialURL: url) { [weak self] success in
            self?.dismissWebview { [weak self] in
                if success {
                    self?.onCompleted?()
                }
            }
        }
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        webViewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(didTapDone))
        navigationController.show(webViewController, sender: navigationController)
    }

    @objc func didTapDone() {
        dismissWebview()
    }

    func dismissWebview(completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
            completion?()
        }
    }
}

private extension StoreOnboardingPaymentsSetupCoordinator {
    enum Localization {
        static let wcPayWebviewTitle = NSLocalizedString(
            "WooPayments",
            comment: "Title of the webview for WCPay setup from onboarding."
        )
        static let paymentsWebviewTitle = NSLocalizedString(
            "Payments",
            comment: "Title of the webview for payments setup from onboarding."
        )
    }

    enum URLs {
        static func wcPay(site: Site) -> String {
            "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-admin&task=woocommerce-payments"
        }

        static func payments(site: Site) -> String {
            "\(site.adminURL.removingSuffix("/"))/admin.php?page=wc-admin&task=payments"
        }
    }
}
