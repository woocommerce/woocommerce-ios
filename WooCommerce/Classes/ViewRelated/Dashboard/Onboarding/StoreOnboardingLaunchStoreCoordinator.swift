import UIKit
import SwiftUI
import struct Yosemite.Site

/// Coordinates navigation of the launch store action from store onboarding.
final class StoreOnboardingLaunchStoreCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let site: Site
    private let isLaunched: Bool
    private let onLaunch: (() -> Void)?

    /// - Parameters:
    ///   - site: The site for the launch store onboarding task.
    ///   - isLaunched: Whether the site has already been launched.
    ///   - navigationController: The navigation controller that presents the launch store flow.
    ///   - onLaunch: Called when the site is launched from the launch store flow.
    init(site: Site, isLaunched: Bool, navigationController: UINavigationController, onLaunch: (() -> Void)? = nil) {
        self.site = site
        self.isLaunched = isLaunched
        self.navigationController = navigationController
        self.onLaunch = onLaunch
    }

    func start() {
        guard let siteURL = URL(string: site.url) else {
            assertionFailure("The site does not have a valid URL to launch from store onboarding: \(site).")
            return
        }

        // Navigation controller for the launch store flow.
        let modalNavigationController = WooNavigationController()
        if isLaunched {
            presentLaunchedView(siteURL: siteURL, in: modalNavigationController)
        } else {
            presentLaunchStoreView(siteURL: siteURL, in: modalNavigationController)
        }
    }
}

private extension StoreOnboardingLaunchStoreCoordinator {
    func presentLaunchStoreView(siteURL: URL, in modalNavigationController: UINavigationController) {
        let launchStoreController = StoreOnboardingLaunchStoreHostingController(viewModel: .init(siteURL: siteURL, siteID: site.siteID) { [weak self] in
            guard let self else { return }
            self.showLaunchedView(siteURL: siteURL, in: modalNavigationController)
            self.onLaunch?()
        })
        modalNavigationController.pushViewController(launchStoreController, animated: false)
        navigationController.present(modalNavigationController, animated: true)
    }

    func presentLaunchedView(siteURL: URL, in modalNavigationController: UINavigationController) {
        let launchedStoreController = createLaunchedStoreController(siteURL: siteURL)
        modalNavigationController.pushViewController(launchedStoreController, animated: false)
        navigationController.present(modalNavigationController, animated: true)
    }

    func showLaunchedView(siteURL: URL, in modalNavigationController: UINavigationController) {
        let launchedStoreController = createLaunchedStoreController(siteURL: siteURL)
        modalNavigationController.pushViewController(launchedStoreController, animated: true)
    }

    func dismiss() {
        navigationController.dismiss(animated: true)
    }
}

private extension StoreOnboardingLaunchStoreCoordinator {
    func createLaunchedStoreController(siteURL: URL) -> UIViewController {
        StoreOnboardingStoreLaunchedHostingController(siteURL: siteURL) { [weak self] in
            self?.dismiss()
        }
    }
}
