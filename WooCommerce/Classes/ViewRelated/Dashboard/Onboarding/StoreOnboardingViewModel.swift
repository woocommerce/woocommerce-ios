import Foundation
import UIKit
import Yosemite

/// View model for `StoreOnboardingView`.
class StoreOnboardingViewModel: ObservableObject {
    /// UI state of the dashboard top performers.
    enum State {
        /// Shows placeholder rows.
        case loading
        /// Shows a list of onboarding tasks
        case loaded(rows: [StoreOnboardingTaskViewModel])
    }

    @Published private(set) var isRedacted: Bool = false
    @Published private(set) var taskViewModels: [StoreOnboardingTaskViewModel] = []

    /// Set externally in the hosting controller to invalidate the SwiftUI `StoreOnboardingView`'s intrinsic content size as a workaround with UIKit.
    var onStateChange: (() -> Void)?

    var numberOfTasksCompleted: Int {
        taskViewModels
            .filter({ $0.isComplete })
            .count
    }

    var tasksForDisplay: [StoreOnboardingTaskViewModel] {
        guard isRedacted == false else {
            return placeholderTasks
        }
        guard !isExpanded else {
            return taskViewModels
        }
        let maxNumberOfTasksToDisplayInCollapsedMode = 3
        let incompleteTasks = taskViewModels.filter({ !$0.isComplete })
        return isExpanded ? taskViewModels : Array(incompleteTasks.prefix(maxNumberOfTasksToDisplayInCollapsedMode))
    }

    let isExpanded: Bool

    private let siteID: Int64

    private let stores: StoresManager

    private var state: State

    private let placeholderTasks: [StoreOnboardingTaskViewModel] = Array(repeating: StoreOnboardingTaskViewModel.placeHolder(),
                                                                         count: 3)

    /// - Parameter isExpanded: Whether the onboarding view is in the expanded state. The expanded state is shown when the view is in fullscreen.
    init(isExpanded: Bool,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.isExpanded = isExpanded
        self.siteID = siteID
        self.stores = stores
        self.state = .loading
    }

    func reloadTasks() async {
        await update(state: .loading)
        let tasks = try? await loadTasks()
        await update(state: .loaded(rows: tasks ?? taskViewModels))
    }
}

private extension StoreOnboardingViewModel {
    @MainActor
    private func loadTasks() async throws -> [StoreOnboardingTaskViewModel] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StoreOnboardingTasksAction.loadOnboardingTasks(siteID: siteID) { result in
                continuation.resume(with: result
                    .map { $0.filter({ task in
                        if case .unsupported = task.type {
                            return false
                        } else {
                            return true
                        }
                    }).map { .init(task: $0) }})
            })
        }
    }

    @MainActor
    func update(state: State) {
        switch state {
        case .loading:
            isRedacted = true
        case .loaded(let items):
            isRedacted = false
            self.taskViewModels = items
        }
        onStateChange?()
    }
}

private extension StoreOnboardingTaskViewModel {
    static func placeHolder() -> Self {
        .init(task: .init(isComplete: true,
                          type: .launchStore))
    }
}
