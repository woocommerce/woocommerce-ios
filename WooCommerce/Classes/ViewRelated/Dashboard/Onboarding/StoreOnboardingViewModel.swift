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
    private let featureFlagService: FeatureFlagService

    private var state: State

    private let placeholderTasks: [StoreOnboardingTaskViewModel] = [.placeHolder(), .placeHolder(), .placeHolder()]

    private let defaults: UserDefaults

    private let analytics: Analytics

    private let waitingTimeTracker: AppStartupWaitingTimeTracker

    private var isFreeTrialStore: Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }
        return site.isFreeTrialSite
    }

    private var siteHasDefaultTitle: Bool {
        stores.sessionManager.defaultSite?.name == WooConstants.defaultStoreName
    }

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
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         waitingTimeTracker: AppStartupWaitingTimeTracker = ServiceLocator.startupWaitingTimeTracker) {
        self.siteID = siteID
        self.isExpanded = isExpanded
        self.stores = stores
        self.state = .loading
        self.defaults = defaults
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        isHideStoreOnboardingTaskListFeatureEnabled = featureFlagService.isFeatureFlagEnabled(.hideStoreOnboardingTaskList)
        self.waitingTimeTracker = waitingTimeTracker

        Publishers.CombineLatest3($noTasksAvailableForDisplay,
                                  defaults.publisher(for: \.completedAllStoreOnboardingTasks),
                                  defaults.publisher(for: \.shouldHideStoreOnboardingTaskList))
        .map { !($0 || $1 || $2) }
        .assign(to: &$shouldShowInDashboard)
    }

    func reloadTasks() async {
        guard !defaults.completedAllStoreOnboardingTasks else {
            waitingTimeTracker.end(action: .loadOnboardingTasks)
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
        analytics.track(event: .StoreOnboarding.storeOnboardingShowOrHideList(isHiding: true,
                                                                              source: .onboardingList,
                                                                              pendingTasks: pending))
        defaults[.shouldHideStoreOnboardingTaskList] = true
    }
}

private extension StoreOnboardingViewModel {
    @MainActor
    func loadTasks() async throws -> [StoreOnboardingTaskViewModel] {

        let localTasks: [StoreOnboardingTask] = {
            var tasks: [StoreOnboardingTask] = []
            if isFreeTrialStore {
                tasks.append(.init(isComplete: false, type: .launchStore))
                tasks.append(.init(isComplete: !siteHasDefaultTitle, type: .storeName))
            }
            return tasks
        }()

        let tasksFromServer: [StoreOnboardingTask] = try await fetchTasks()

        return (tasksFromServer + localTasks)
            .sorted()
            .map { .init(task: $0, badgeText: badgeText(task: $0.type)) }
    }

    func badgeText(task: StoreOnboardingTask.TaskType) -> String? {
        switch task {
        case .addFirstProduct:
            let isEligibleForProductDescriptionAI: Bool = {
                guard featureFlagService.isFeatureFlagEnabled(.productDescriptionAIFromStoreOnboarding) else {
                    return false
                }
                let eligibilityChecker = ProductFormAIEligibilityChecker(site: stores.sessionManager.defaultSite, featureFlagService: featureFlagService)
                return eligibilityChecker.isFeatureEnabled(.description)
            }()
            return isEligibleForProductDescriptionAI ? StoreOnboardingTaskViewModel.Localization.AddFirstProduct.badgeText: nil
        default:
            return nil
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
            stores.dispatch(StoreOnboardingTasksAction.loadOnboardingTasks(siteID: siteID) { [weak self] result in
                switch result {
                case .success(let tasks):
                    self?.waitingTimeTracker.end(action: .loadOnboardingTasks)
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
                    self?.waitingTimeTracker.end() // Stop the tracker if there is an error.
                    return continuation.resume(throwing: error)
                }
            })
        })
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
