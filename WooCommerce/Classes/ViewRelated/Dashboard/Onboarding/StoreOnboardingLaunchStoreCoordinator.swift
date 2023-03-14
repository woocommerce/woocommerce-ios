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
        let launchStoreController = UIHostingController(rootView: StoreOnboardingLaunchStoreView(viewModel: .init(siteURL: siteURL)))
        navigationController.show(launchStoreController, sender: nil)
    }
}
