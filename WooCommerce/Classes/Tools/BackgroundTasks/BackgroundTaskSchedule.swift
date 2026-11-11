import Foundation
import os
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
/// The app updates the schedule on the main thread when entering background, while `BGTaskScheduler` runs task handlers
/// on its own queue, so the dates are guarded by a lock.
/// `@unchecked` because `TimeProvider` is not `Sendable`; the schedule only calls `now()` on it.
///
final class BackgroundTaskSchedule: @unchecked Sendable {
    private let preferredTaskDate = OSAllocatedUnfairLock<[BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date]>(initialState: [:])
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
        updateDates { dates in
            for task in BackgroundTaskRefreshDispatcher.BackgroundTaskType.allCases {
                dates[task] = timeProvider.now().addingTimeInterval(task.period)
            }
        }
    }

    func getNextTask() -> BackgroundTaskRefreshDispatcher.BackgroundTaskType {
        return BackgroundTaskRefreshDispatcher.BackgroundTaskType.allCases.min { task1, task2 in
            preferredRunDate(for: task1) < preferredRunDate(for: task2)
        } ?? .ordersAndDashboardSync
    }

    func preferredRunDate(for task: BackgroundTaskRefreshDispatcher.BackgroundTaskType) -> Date {
        if let preferred = preferredTaskDate.withLock({ $0[task] }) {
            return preferred
        }
        return updateDates { dates in
            if let preferred = dates[task] {
                return preferred
            }
            let next = timeProvider.now().addingTimeInterval(task.period)
            dates[task] = next
            return next
        }
    }

    func setNextPreferredRunDate(for task: BackgroundTaskRefreshDispatcher.BackgroundTaskType) {
        updateDates { dates in
            dates[task] = timeProvider.now().addingTimeInterval(task.period)
        }
    }
}

// MARK: - Persistence

private extension BackgroundTaskSchedule {
    private var userDefaultsKey: String { "BackgroundTaskSchedule.preferredTaskDate" }

    /// Applies `update` and persists the result while holding the lock, so persisted writes land in the same order as the updates.
    @discardableResult
    private func updateDates<T>(_ update: (inout [BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date]) -> T) -> T {
        preferredTaskDate.withLockUnchecked { dates in
            let result = update(&dates)
            persist(dates)
            return result
        }
    }

    private func loadPersistedDates() {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date].self, from: data)
        else {
            return
        }
        updateDates { $0 = decoded }
    }

    private func persist(_ dates: [BackgroundTaskRefreshDispatcher.BackgroundTaskType: Date]) {
        if let data = try? JSONEncoder().encode(dates) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }
}
