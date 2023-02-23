import Foundation
import UIKit

/// Onboarding tasks to set up a store.
enum StoreOnboardingTask {
    case addFirstProduct
    case launchStore
    case customizeDomains
    case payments
}

/// View model for `StoreOnboardingView`.
final class StoreOnboardingViewModel: ObservableObject {
    struct TaskViewModel {
        let task: StoreOnboardingTask
        let isComplete: Bool
        let icon: UIImage
    }

    @Published private(set) var taskViewModels: [TaskViewModel]

    private let isExpanded: Bool

    /// - Parameter isExpanded: Whether the onboarding view is in the expanded state. The expanded state is shown when the view is in fullscreen.
    init(isExpanded: Bool) {
        self.isExpanded = isExpanded
        // TODO: 8892 - check the complete state from the API
        taskViewModels = [
            .init(task: .addFirstProduct, isComplete: false, icon: .productImage),
            .init(task: .launchStore, isComplete: false, icon: .launchStoreImage),
            .init(task: .customizeDomains, isComplete: false, icon: .domainsImage),
            .init(task: .payments, isComplete: false, icon: .currencyImage)
        ]
    }
}
