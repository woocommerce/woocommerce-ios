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
        let onboardingController = UIHostingController(rootView: StoreOnboardingView(viewModel: .init(isExpanded: true), taskTapped: { [weak self] task in
            self?.start(task: task)
        }))
        navigationController.show(onboardingController, sender: self)
    }

    func start(task: StoreOnboardingTask) {
        print("TODO: navigate to \(task)")
        start()
    }
}
