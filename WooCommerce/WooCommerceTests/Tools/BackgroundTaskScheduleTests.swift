@testable import WooCommerce
import Foundation
import Testing
import WooFoundation

struct BackgroundTaskScheduleTests {
    private let sut: BackgroundTaskSchedule
    private let timeProvider: MockTimeProvider

    init() {
        timeProvider = MockTimeProvider()
        let userDefaults = InMemoryUserDefaults()

        sut = BackgroundTaskSchedule(timeProvider: timeProvider, userDefaults: userDefaults)
    }

    @Test func initial_state_returns_task_with_shortest_period() {
        // Given - Fresh schedule with no preferred dates set

        // When
        let nextTask = sut.getNextTask()

        // Then - Orders sync has shorter period (30min vs 60min)
        #expect(nextTask == .ordersAndDashboardSync)
    }

    @Test func setDefaultPreferredTaskDates_schedules_all_tasks_from_now() {
        // Given
        let startTime = Date(timeIntervalSince1970: 1000)
        timeProvider.set(now: startTime)

        // When
        sut.setDefaultPreferredTaskDates()

        // Then - All tasks should have preferred dates set from current time
        let ordersDate = sut.preferredRunDate(for: .ordersAndDashboardSync)
        let posDate = sut.preferredRunDate(for: .posCatalogSync)

        #expect(ordersDate == startTime.addingTimeInterval(30 * 60))  // 30 minutes
        #expect(posDate == startTime.addingTimeInterval(60 * 60))     // 60 minutes
    }

    @Test func background_task_execution_simulation_over_extended_period() {
        // Given - App enters background at T=0
        let startTime = Date(timeIntervalSince1970: 0)
        timeProvider.set(now: startTime)
        sut.setDefaultPreferredTaskDates()

        // Expected: Orders (30min), POS (60min)
        var nextTask = sut.getNextTask()
        #expect(nextTask == .ordersAndDashboardSync)

        // When - System executes orders sync at T=35min (5min late)
        timeProvider.advance(by: 35 * 60)
        sut.setNextPreferredRunDate(for: .ordersAndDashboardSync)

        // Then - Next should be POS (preferred at T=60, in 25min)
        nextTask = sut.getNextTask()
        #expect(nextTask == .posCatalogSync)
        #expect(sut.preferredRunDate(for: .posCatalogSync) == startTime.addingTimeInterval(60 * 60))

        // When - System executes POS sync at T=75min (15min late)
        timeProvider.advance(by: 40 * 60)  // Now at T=75min
        sut.setNextPreferredRunDate(for: .posCatalogSync)

        // Then - Orders is next (preferred at T=65, already overdue by 10min)
        nextTask = sut.getNextTask()
        #expect(nextTask == .ordersAndDashboardSync)
        let ordersPreferred = sut.preferredRunDate(for: .ordersAndDashboardSync)
        #expect(ordersPreferred == startTime.addingTimeInterval(65 * 60))

        // When - System executes orders at T=80min (15min late from T=65)
        timeProvider.advance(by: 5 * 60)  // Now at T=80min
        sut.setNextPreferredRunDate(for: .ordersAndDashboardSync)

        // Then - Orders is next again (preferred at T=110min, in 30min)
        // POS is preferred at T=135min (in 55min)
        nextTask = sut.getNextTask()
        #expect(nextTask == .ordersAndDashboardSync)
        #expect(sut.preferredRunDate(for: .ordersAndDashboardSync) == startTime.addingTimeInterval(110 * 60))
        #expect(sut.preferredRunDate(for: .posCatalogSync) == startTime.addingTimeInterval(135 * 60))
    }

    @Test func tasks_execute_at_random_times_maintains_correct_scheduling() {
        // Given - Simulate realistic background task execution with system delays
        let startTime = Date(timeIntervalSince1970: 0)
        timeProvider.set(now: startTime)
        sut.setDefaultPreferredTaskDates()

        // When/Then - Track 10 background executions with varying delays
        var executionLog: [(time: TimeInterval, task: BackgroundTaskRefreshDispatcher.BackgroundTaskType)] = []

        // Execution 1: Orders at T=0min (immediate, unusual but possible)
        let task1 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task1)
        executionLog.append((0, task1))
        #expect(task1 == .ordersAndDashboardSync)

        // Execution 2: Orders again at T=32min (2min late from T=30)
        timeProvider.advance(by: 32 * 60)
        let task2 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task2)
        executionLog.append((32, task2))
        #expect(task2 == .ordersAndDashboardSync)

        // Execution 3: POS at T=58min (2min early from T=60)
        timeProvider.advance(by: 26 * 60)
        let task3 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task3)
        executionLog.append((58, task3))
        #expect(task3 == .posCatalogSync)

        // Execution 4: Orders at T=70min (8min late from T=62)
        timeProvider.advance(by: 12 * 60)
        let task4 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task4)
        executionLog.append((70, task4))
        #expect(task4 == .ordersAndDashboardSync)

        // Execution 5: Orders at T=105min (5min late from T=100)
        timeProvider.advance(by: 35 * 60)
        let task5 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task5)
        executionLog.append((105, task5))
        #expect(task5 == .ordersAndDashboardSync)

        // Execution 6: POS at T=118min (exactly on time from T=118)
        timeProvider.advance(by: 13 * 60)
        let task6 = sut.getNextTask()
        sut.setNextPreferredRunDate(for: task6)
        executionLog.append((118, task6))
        #expect(task6 == .posCatalogSync)

        // Then - Verify next preferred dates are correctly calculated
        let ordersNext = sut.preferredRunDate(for: .ordersAndDashboardSync)
        let posNext = sut.preferredRunDate(for: .posCatalogSync)

        // Orders: T=105 + 30 = T=135
        #expect(ordersNext == startTime.addingTimeInterval(135 * 60))
        // POS: T=118 + 60 = T=178
        #expect(posNext == startTime.addingTimeInterval(178 * 60))

        // Next task should be Orders (T=135 < T=178)
        #expect(sut.getNextTask() == .ordersAndDashboardSync)
    }

    @Test func task_with_overdue_preferred_date_is_selected_first() {
        // Given - Both tasks overdue, but orders more overdue
        let startTime = Date(timeIntervalSince1970: 1000)
        timeProvider.set(now: startTime)
        sut.setDefaultPreferredTaskDates()

        // Advance time so both tasks are overdue
        timeProvider.advance(by: 90 * 60)  // 90 minutes later

        // When
        let nextTask = sut.getNextTask()

        // Then - Orders should be selected (preferred at T+30, more overdue than POS at T+60)
        #expect(nextTask == .ordersAndDashboardSync)
    }

    @Test func preferredRunDate_creates_date_on_first_access() {
        // Given - No preferred dates set
        let startTime = Date(timeIntervalSince1970: 2000)
        timeProvider.set(now: startTime)

        // When - Access preferred date without setting defaults
        let ordersDate = sut.preferredRunDate(for: .ordersAndDashboardSync)

        // Then - Should create date = now + period
        #expect(ordersDate == startTime.addingTimeInterval(30 * 60))

        // When - Access again
        let ordersDate2 = sut.preferredRunDate(for: .ordersAndDashboardSync)

        // Then - Should return same date (cached)
        #expect(ordersDate2 == ordersDate)
    }

    @Test func setNextPreferredRunDate_updates_from_current_time() {
        // Given
        let startTime = Date(timeIntervalSince1970: 0)
        timeProvider.set(now: startTime)
        sut.setDefaultPreferredTaskDates()

        let initialDate = sut.preferredRunDate(for: .ordersAndDashboardSync)
        #expect(initialDate == startTime.addingTimeInterval(30 * 60))

        // When - Advance time and update preferred date
        timeProvider.advance(by: 45 * 60)
        sut.setNextPreferredRunDate(for: .ordersAndDashboardSync)

        // Then - New preferred date should be from new current time
        let newDate = sut.preferredRunDate(for: .ordersAndDashboardSync)
        #expect(newDate == startTime.addingTimeInterval((45 + 30) * 60))
    }
}

// MARK: - Mocks

private class MockTimeProvider: TimeProvider {
    private var currentTime: Date

    init(startTime: Date = Date(timeIntervalSince1970: 0)) {
        self.currentTime = startTime
    }

    func set(now date: Date) {
        currentTime = date
    }

    func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)
    }

    func now() -> Date {
        currentTime
    }

    func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer {
        fatalError("not implemented")
    }
}

/// In-memory UserDefaults that doesn't persist to disk
/// Each instance has its own isolated storage
private class InMemoryUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}
