import Foundation
import UIKit
import Yosemite
import Combine

/// View model for `StoreOnboardingView`.
class StoreOnboardingViewModel: ObservableObject {
    /// UI state of the store onboarding tasks.
    enum State {
        /// Shows placeholder rows.
        case loading
        /// Shows a list of onboarding tasks
        case loaded(rows: [StoreOnboardingTaskViewModel])
        /// When the request fails and there is no previously loaded local data
        case failed
    }

    @Published private(set) var isRedacted: Bool = false
    @Published private(set) var taskViewModels: [StoreOnboardingTaskViewModel] = []

    /// Used to determine whether the task list should be displayed in dashboard
    ///
    @Published private(set) var shouldShowInDashboard: Bool = false

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

        if isExpanded || !shouldShowViewAllButton {
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

    private let placeholderTasks: [StoreOnboardingTaskViewModel] = [.placeHolder(), .placeHolder(), .placeHolder()]

    private let defaults: UserDefaults

    /// Emits when there are no tasks available for display after reload.
    /// i.e. When (request failed && No previously loaded local data available)
    ///
    @Published private var noTasksAvailableForDisplay: Bool = false

    /// - Parameters:
    ///   - siteID: siteID
    ///   - isExpanded: Whether the onboarding view is in the expanded state. The expanded state is shown when the view is in fullscreen.
    ///   - stores: StoresManager
    ///   - defaults: UserDefaults for storing when all onboarding tasks are completed
    init(siteID: Int64,
         isExpanded: Bool,
         stores: StoresManager = ServiceLocator.stores,
         defaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.isExpanded = isExpanded
        self.stores = stores
        self.state = .loading
        self.defaults = defaults

        Publishers.CombineLatest($noTasksAvailableForDisplay,
                                 defaults.publisher(for: \.completedAllStoreOnboardingTasks))
        .map { !($0 || $1) }
        .assign(to: &$shouldShowInDashboard)
    }

    func reloadTasks() async {
        guard !defaults.completedAllStoreOnboardingTasks else {
            return
        }

        await update(state: .loading)
        if let tasks = try? await loadTasks(),
           tasks.isNotEmpty {
            await checkIfAllTasksAreCompleted(tasks)
            await update(state: .loaded(rows: tasks))
        } else if taskViewModels.isNotEmpty {
            await update(state: .loaded(rows: taskViewModels))
        } else {
            await update(state: .failed)
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
            taskViewModels = items
            if hasPendingTasks(items) {
                ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingShown())
            }
        case .failed:
            isRedacted = false
            taskViewModels = []
            noTasksAvailableForDisplay = true
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

        if hasPendingTasks(taskViewModels) {
            // Tracks the onboarding completion event only when there are any pending tasks before and
            // now all tasks are complete.
            ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingCompleted())
        }

        // This will be reset to `nil` when session resets
        defaults[.completedAllStoreOnboardingTasks] = true
    }

    func hasPendingTasks(_ tasks: [StoreOnboardingTaskViewModel]) -> Bool {
        tasks.contains(where: { $0.isComplete == false })
    }
}

private extension StoreOnboardingTaskViewModel {
    static func placeHolder() -> Self {
        .init(task: .init(isComplete: true,
                          type: .launchStore))
    }
}

extension UserDefaults {
     @objc dynamic var completedAllStoreOnboardingTasks: Bool {
         bool(forKey: Key.completedAllStoreOnboardingTasks.rawValue)
     }
 }
