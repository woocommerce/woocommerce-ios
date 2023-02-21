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
        let onboardingController = UIHostingController(rootView: StoreOnboardingView(viewModel: .init(isExpanded: true), taskTapped: { [weak self] task in
            self?.start(task: task)
        }))
        navigationController.show(onboardingController, sender: self)
    }

    /// Navigates to complete an onboarding task.
    /// - Parameter task: the task to complete.
    func start(task: StoreOnboardingTask) {
        print("TODO: navigate to \(task)")
        start()
    }
}
