import UIKit
import SwiftUI
import struct Yosemite.Site

/// Coordinates navigation of the launch store action from store onboarding.
final class StoreOnboardingLaunchStoreCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let site: Site
    private let isLaunched: Bool
    private let onLearnMoreTapped: () -> Void
    private let onStoreLaunched: (() -> Void)?

    /// - Parameters:
    ///   - site: The site for the launch store onboarding task.
    ///   - isLaunched: Whether the site has already been launched.
    ///   - navigationController: The navigation controller that presents the launch store flow.
    ///   - onLearnMoreTapped: Fired upon tapping `LearnMore` button from free trial banner.
    ///   - onStoreLaunched: Fired when the store is launched successfully
    init(site: Site,
         isLaunched: Bool,
         navigationController: UINavigationController,
         onLearnMoreTapped: @escaping () -> Void,
         onStoreLaunched: (() -> Void)? = nil) {
        self.site = site
        self.isLaunched = isLaunched
        self.navigationController = navigationController
        self.onLearnMoreTapped = onLearnMoreTapped
        self.onStoreLaunched = onStoreLaunched
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
            self?.onStoreLaunched?()
            self?.showLaunchedView(siteURL: siteURL, in: modalNavigationController)
        } onLearnMoreTapped: { [weak self] in
            self?.dismiss()
            self?.onLearnMoreTapped()
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
