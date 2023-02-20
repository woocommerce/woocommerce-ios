import Foundation
import SwiftUI
import UIKit

final class StoreOnboardingCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    /// Navigates to the fullscreen store onboarding view.
    func start() {
        let onboarding = UIHostingController(rootView: StoreOnboardingView(viewModel: .init(isExpanded: true)))
        navigationController.show(onboarding, sender: self)
    }

    func start(task: StoreOnboardingTask) {
        print("TODO: navigate to \(task)")
    }
}
