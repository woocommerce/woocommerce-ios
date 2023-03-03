import Foundation
import UIKit
import Yosemite

/// View model for `StoreOnboardingView`.
final class StoreOnboardingViewModel: ObservableObject {
    /// UI state of the dashboard top performers.
    enum State {
        /// Shows placeholder rows.
        case loading
        /// Shows a list of onboarding tasks
        case loaded(rows: [TaskViewModel])
    }

    struct TaskViewModel: Identifiable, Equatable {
        let id = UUID()
        let task: StoreOnboardingTask
        let icon: UIImage
        let title: String
        let subtitle: String

        var isComplete: Bool {
            task.isComplete
        }

        init(task: StoreOnboardingTask) {
            self.task = task
            switch task.type {
            case .addFirstProduct:
                icon = .productImage
                title = NSLocalizedString(
                    "Add your first product",
                    comment: "Title of the store onboarding task to add the first product."
                )
                subtitle = NSLocalizedString(
                    "Start selling by adding products or services to your store.",
                    comment: "Subtitle of the store onboarding task to add the first product."
                )
            case .launchStore:
                icon = .launchStoreImage
                title = NSLocalizedString(
                    "Launch your store",
                    comment: "Title of the store onboarding task to launch the store."
                )
                subtitle = NSLocalizedString(
                    "Publish your site to the world anytime you want!",
                    comment: "Subtitle of the store onboarding task to launch the store."
                )
            case .customizeDomains:
                icon = .domainsImage
                title = NSLocalizedString(
                    "Customize your domain",
                    comment: "Title of the store onboarding task to customize the store domain."
                )
                subtitle = NSLocalizedString(
                    "Have a custom URL to host your store.",
                    comment: "Subtitle of the store onboarding task to customize the store domain."
                )
            case .payments:
                icon = .currencyImage
                title = NSLocalizedString(
                    "Get paid",
                    comment: "Title of the store onboarding task to get paid."
                )
                subtitle = NSLocalizedString(
                    "Give your customers an easy and convenient way to pay!",
                    comment: "Subtitle of the store onboarding task to get paid."
                )
            case .unsupported:
                icon = .checkCircleImage
                title = ""
                subtitle = ""
            }
        }

        static func placeHolder() -> TaskViewModel {
            .init(task: .init(isComplete: true,
                              type: .launchStore))
        }
    }

    @Published private(set) var isRedacted: Bool = false
    @Published private(set) var taskViewModels: [TaskViewModel] = []

    var numberOfTasksCompleted: Int {
        taskViewModels
            .filter({ $0.isComplete })
            .count
    }

    var tasksForDisplay: [TaskViewModel] {
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

    private let placeholderTasks: [TaskViewModel] = Array(repeating: TaskViewModel.placeHolder(),
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
    private func loadTasks() async throws -> [TaskViewModel] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(StoreOnboardingTasksAction.loadOnboardingTasks(siteID: siteID) { result in
                continuation.resume(with: result
                    .map { $0.filter({ task in
                        if case .unsupported = task.type {
                            return false
                        } else {
                            return true
                        }
                    }).map { TaskViewModel(task: $0) }})
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
    }
}
