import Foundation
import SwiftUI
import UIKit

/// Coordinates navigation for store onboarding.
final class StoreOnboardingCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    /// Navigates to the fullscreen store onboarding view.
    func start() {
        let onboardingController = UINavigationController(rootViewController: StoreOnboardingViewHostingController(viewModel: .init(isExpanded: true),
                                                 taskTapped: { [weak self] task in self?.start(task: task) }))
        navigationController.present(onboardingController, animated: true)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    func start(task: StoreOnboardingTask) {
        #warning("TODO: handle navigation for each onboarding task")
        start()
    }
}
