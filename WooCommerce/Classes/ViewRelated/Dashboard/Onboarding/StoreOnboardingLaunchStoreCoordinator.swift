import UIKit
import SwiftUI

final class StoreOnboardingLaunchStoreCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let siteURL: URL

    init(siteURL: URL, navigationController: UINavigationController) {
        self.siteURL = siteURL
        self.navigationController = navigationController
    }

    func start() {
        let launchStoreController = StoreOnboardingLaunchStoreHostingController(viewModel: .init(siteURL: siteURL))
        navigationController.present(WooNavigationController(rootViewController: launchStoreController), animated: true)
    }
}
