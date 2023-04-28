import Foundation
import UIKit
import Yosemite
import Combine
import Experiments

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

    @Published private(set) var isRedacted: Bool = true
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

        if isExpanded {
            return taskViewModels
        }

        let incompleteTasks = Array(taskViewModels.filter({ !$0.isComplete }).prefix(Constants.maxNumberOfTasksToDisplayInCollapsedMode))
        return incompleteTasks
    }

    var shouldShowViewAllButton: Bool {
        !isExpanded && !isRedacted && (taskViewModels.count > tasksForDisplay.count)
    }

    let isHideStoreOnboardingTaskListFeatureEnabled: Bool

    let isExpanded: Bool

    private let siteID: Int64

    private let stores: StoresManager

    private var state: State

    private let placeholderTasks: [StoreOnboardingTaskViewModel] = [.placeHolder(), .placeHolder(), .placeHolder()]

    private let defaults: UserDefaults

    private let analytics: Analytics

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
         defaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.isExpanded = isExpanded
        self.stores = stores
        self.state = .loading
        self.defaults = defaults
        self.analytics = analytics
        isHideStoreOnboardingTaskListFeatureEnabled = featureFlagService.isFeatureFlagEnabled(.hideStoreOnboardingTaskList)

        Publishers.CombineLatest3($noTasksAvailableForDisplay,
                                  defaults.publisher(for: \.completedAllStoreOnboardingTasks),
                                  defaults.publisher(for: \.shouldHideStoreOnboardingTaskList))
        .map { !($0 || $1 || $2) }
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

    func hideTaskList() {
        let pending = taskViewModels
            .filter { !$0.isComplete }
            .map { $0.task.type }
        analytics.track(event: .StoreOnboarding.storeOnboardingHideList(source: .onboardingList,
                                                                        pendingTasks: pending))
        defaults[.shouldHideStoreOnboardingTaskList] = true
    }
}

private extension StoreOnboardingViewModel {
    @MainActor
    func loadTasks() async throws -> [StoreOnboardingTaskViewModel] {
        async let shouldManuallyAppendLaunchStoreTask = isFreeTrialPlan
        let tasksFromServer: [StoreOnboardingTask] = try await fetchTasks()

        if await shouldManuallyAppendLaunchStoreTask {
            return (tasksFromServer + [.init(isComplete: false, type: .launchStore)])
                .sorted()
                .map { .init(task: $0) }
        } else {
            return tasksFromServer
                .map { .init(task: $0) }
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
                analytics.track(event: .StoreOnboarding.storeOnboardingShown())
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
            analytics.track(event: .StoreOnboarding.storeOnboardingCompleted())
        }

        // This will be reset to `nil` when session resets
        defaults[.completedAllStoreOnboardingTasks] = true
    }

    @MainActor
    func fetchTasks() async throws -> [StoreOnboardingTask] {
        try await withCheckedThrowingContinuation({ continuation in
            stores.dispatch(StoreOnboardingTasksAction.loadOnboardingTasks(siteID: siteID) { result in
                switch result {
                case .success(let tasks):
                    return continuation.resume(returning: tasks.filter({ task in
                        if case .unsupported = task.type {
                            return false
                        } else {
                            return true
                        }
                    }).map({ [weak self] task in
                        // If store is already live and launchStore task is incomplete
                        // mark the task as complete.
                        //
                        // We do this as a workaround because there is an issue with the backend
                        // and `launchStore` task is marked as `incomplete` for already live stores.
                        //
                        // More info at https://github.com/woocommerce/woocommerce-ios/issues/9477
                        guard let self,
                              case .launchStore = task.type,
                              !task.isComplete,
                              self.stores.sessionManager.defaultSite?.isPublic == true else {
                            return task
                        }

                        return StoreOnboardingTask(isComplete: true, type: .launchStore)
                    }))
                case .failure(let error):
                    return continuation.resume(throwing: error)
                }
            })
        })
    }

    @MainActor
    var isFreeTrialPlan: Bool {
        get async {
            // Only fetch free trial information if the site is a WPCom site.
            guard stores.sessionManager.defaultSite?.isWordPressComStore == true else {
                return false
            }

            return await withCheckedContinuation({ continuation in
                let action = PaymentAction.loadSiteCurrentPlan(siteID: siteID) { result in
                    switch result {
                    case .success(let plan):
                        return continuation.resume(returning: plan.isFreeTrial)
                    case .failure(let error):
                        DDLogError("⛔️ Error fetching the current site's plan information: \(error)")
                        return continuation.resume(returning: false)
                    }
                }
                stores.dispatch(action)
            })
        }
    }

    func hasPendingTasks(_ tasks: [StoreOnboardingTaskViewModel]) -> Bool {
        tasks.contains(where: { $0.isComplete == false })
    }
}

private extension StoreOnboardingViewModel {
    enum Constants {
        static let maxNumberOfTasksToDisplayInCollapsedMode = 3
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

    @objc dynamic var shouldHideStoreOnboardingTaskList: Bool {
        bool(forKey: Key.shouldHideStoreOnboardingTaskList.rawValue)
    }
 }
