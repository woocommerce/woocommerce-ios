import UIKit
import SwiftUI
import struct Yosemite.Site

/// Coordinates navigation of the launch store action from store onboarding.
final class StoreOnboardingLaunchStoreCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let site: Site

    init(site: Site, navigationController: UINavigationController) {
        self.site = site
        self.navigationController = navigationController
    }

    func start() {
        guard let siteURL = URL(string: site.url) else {
            assertionFailure("The site does not have a valid URL to launch from store onboarding: \(site).")
            return
        }
        let launchStoreController = StoreOnboardingLaunchStoreHostingController(viewModel: .init(siteURL: siteURL, siteID: site.siteID) { [weak self] in
            self?.showLaunchedView()
        })
        navigationController.present(WooNavigationController(rootViewController: launchStoreController), animated: true)
    }
}

private extension StoreOnboardingLaunchStoreCoordinator {
    func showLaunchedView() {
        print("🚀 site launched")
    }
}
