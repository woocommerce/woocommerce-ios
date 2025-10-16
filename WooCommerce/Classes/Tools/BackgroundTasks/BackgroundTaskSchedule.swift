import Foundation
import WooFoundation

extension BackgroundTaskRefreshDispatcher.BackgroundTaskType {
    var period: TimeInterval {
        switch self {
        case .ordersAndDashboardSync:
            return 30 * 60 // 30 minutes
        case .posCatalogSync:
            return 60 * 60 // 60 minutes
        }
    }
}

/// BackgroundTaskSchedule is a helper tool to determine the next BackgroundTask based on the preferred run period
///
final class BackgroundTaskSchedule {
    private var preferredTaskDate: [BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date] = [:] {
        didSet { setPersistedDates () }
    }
    private let timeProvider: TimeProvider
    private let userDefaults: UserDefaults

    init(timeProvider: TimeProvider = DefaultTimeProvider(),
         userDefaults: UserDefaults = .standard) {
        self.timeProvider = timeProvider
        self.userDefaults = userDefaults
        loadPersistedDates()
    }

    // Set preferred task dates when going into background
    // This allows to pick the most appropriate next task
    /// Example:
    /// Set preferred dates Task A: in 30 min and Task B: in 45 min when app enters background
    /// System executes Task A after 40 min. It allows us to know that preferred time for Task B is in 5 min, not 45 min
    /// Next task is Task B with preferred time in 5 minutes
    ///
    func setDefaultPreferredTaskDates() {
        for task in BackgroundTaskRefreshDispatcher.BackgroundTaskType.allCases {
            preferredTaskDate[task] = timeProvider.now().addingTimeInterval(task.period)
        }
    }

    func getNextTask() -> BackgroundTaskRefreshDispatcher.BackgroundTaskType {
        return BackgroundTaskRefreshDispatcher.BackgroundTaskType.allCases.min { task1, task2 in
            preferredRunDate(for: task1) < preferredRunDate(for: task2)
        } ?? .ordersAndDashboardSync
    }

    func preferredRunDate(for task: BackgroundTaskRefreshDispatcher.BackgroundTaskType) -> Date {
        if let preferred = preferredTaskDate[task] {
            return preferred
        }
        let next = timeProvider.now().addingTimeInterval(task.period)
        preferredTaskDate[task] = next
        return next
    }

    func setNextPreferredRunDate(for task: BackgroundTaskRefreshDispatcher.BackgroundTaskType) {
        preferredTaskDate[task] = timeProvider.now().addingTimeInterval(task.period)
    }
}

// MARK: - Persistence

private extension BackgroundTaskSchedule {
    private var userDefaultsKey: String { "BackgroundTaskSchedule.preferredTaskDate" }

    private func loadPersistedDates() {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date].self, from: data)
        else {
            return
        }
        preferredTaskDate = decoded
    }

    private func setPersistedDates() {
        if let data = try? JSONEncoder().encode(preferredTaskDate) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }
}
