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
        let onboardingView = StoreOnboardingView(viewModel: .init(isExpanded: true),
                                                 taskTapped: { [weak self] task in self?.start(task: task) },
                                                 dismissAction: { [weak self] in self?.navigationController.dismiss(animated: true) })
        let onboardingController = UIHostingController(rootView: onboardingView)
        navigationController.present(onboardingController, animated: true)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    func start(task: StoreOnboardingTask) {
        #warning("TODO: handle navigation for each onboarding task")
        start()
    }
}
