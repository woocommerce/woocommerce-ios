import Foundation
import UIKit
import Yosemite

/// View model for `StoreOnboardingView`.
class StoreOnboardingViewModel: ObservableObject {
    /// UI state of the store onboarding tasks.
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
        if isRedacted {
            return placeholderTasks
        }

        if isExpanded {
            return taskViewModels
        }

        if !isExpanded && !shouldShowViewAllButton {
            return taskViewModels
        }

        let maxNumberOfTasksToDisplayInCollapsedMode = 3
        let incompleteTasks = taskViewModels.filter({ !$0.isComplete })
        return isExpanded ? taskViewModels : Array(incompleteTasks.prefix(maxNumberOfTasksToDisplayInCollapsedMode))
    }

    var shouldShowViewAllButton: Bool {
        !isExpanded && !isRedacted && !(taskViewModels.count < 3)
    }

    let isExpanded: Bool

    private let siteID: Int64

    private let stores: StoresManager

    private var state: State

    private let placeholderTasks: [StoreOnboardingTaskViewModel] = Array(repeating: StoreOnboardingTaskViewModel.placeHolder(),
                                                                         count: 3)

    private let defaults: UserDefaults

    private let whenNoTasksAvailable: (() -> Void)?

    /// - Parameters:
    ///   - isExpanded: Whether the onboarding view is in the expanded state. The expanded state is shown when the view is in fullscreen.
    ///   - siteID: siteID
    ///   - stores: StoresManager
    ///   - defaults: UserDefaults for storing when all onboarding tasks are completed
    ///   - whenNoTasksAvailable: Callback when no tasks are available to display
    init(isExpanded: Bool,
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         defaults: UserDefaults = .standard,
         whenNoTasksAvailable: (() -> Void)? = nil) {
        self.isExpanded = isExpanded
        self.siteID = siteID
        self.stores = stores
        self.state = .loading
        self.defaults = defaults
        self.whenNoTasksAvailable = whenNoTasksAvailable
    }

    func reloadTasks() async {
        await update(state: .loading)
        if let tasks = try? await loadTasks(),
           tasks.isNotEmpty {
            await checkIfAllTasksAreCompleted(tasks)
            await update(state: .loaded(rows: tasks))
        } else if taskViewModels.isNotEmpty {
            await update(state: .loaded(rows: taskViewModels))
        } else {
            await MainActor.run {
                whenNoTasksAvailable?()
            }
            await update(state: .loaded(rows: []))
        }
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

    @MainActor
    func checkIfAllTasksAreCompleted(_ tasksFromServer: [StoreOnboardingTaskViewModel]) {
        guard tasksFromServer.isNotEmpty else {
            return
        }

        let isPendingTaskPresent = tasksFromServer.contains(where: { $0.isComplete == false })
        guard isPendingTaskPresent == false else {
            return
        }

        // This will be reset to `nil` when session resets
        defaults[.completedAllStoreOnboardingTasks] = true
    }
}

private extension StoreOnboardingTaskViewModel {
    static func placeHolder() -> Self {
        .init(task: .init(isComplete: true,
                          type: .launchStore))
    }
}
