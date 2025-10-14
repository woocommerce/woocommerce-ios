import Testing
import UIKit
import BackgroundTasks
@testable import WooCommerce
import WooFoundation

@MainActor
class BackgroundWorkSchedulerTests {
    private let userDefaults: UserDefaults
    private let mockTaskScheduler: MockBackgroundTaskScheduler
    private let mockTimerScheduler: MockTimerScheduler
    private let mockTimeProvider: MockTimeProvider
    private let scheduler: BackgroundWorkScheduler

    init() {
        userDefaults = UserDefaults(suiteName: "BackgroundWorkSchedulerTests")!
        mockTaskScheduler = MockBackgroundTaskScheduler()
        mockTimerScheduler = MockTimerScheduler()
        mockTimeProvider = MockTimeProvider()
        scheduler = BackgroundWorkScheduler(
            userDefaults: userDefaults,
            taskScheduler: mockTaskScheduler,
            timerScheduler: mockTimerScheduler,
            timeProvider: mockTimeProvider
        )
    }


    deinit {
        mockTaskScheduler.submittedRequests.removeAll()
        userDefaults.removePersistentDomain(forName: "BackgroundWorkSchedulerTests")
    }
//
//    @Test func register_registers_work_with_task_scheduler() {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//
//        // When
//        scheduler.register(work)
//
//        // Then
//        #expect(mockTaskScheduler.registeredIdentifiers == ["test.work"])
//        #expect(mockTaskScheduler.registeredHandlers["test.work"] != nil)
//    }
//
//    @Test func register_registers_multiple_work_items() {
//        // Given
//        let work1 = MockBackgroundWork(identifier: "test.work1", period: 60)
//        let work2 = MockBackgroundWork(identifier: "test.work2", period: 120)
//
//        // When
//        scheduler.register(work1)
//        scheduler.register(work2)
//
//        // Then
//        #expect(mockTaskScheduler.registeredIdentifiers.count == 2)
//        #expect(mockTaskScheduler.registeredIdentifiers.contains("test.work1"))
//        #expect(mockTaskScheduler.registeredIdentifiers.contains("test.work2"))
//    }
//
//    @Test func start_sets_up_scheduler() {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//
//        // When
//        scheduler.start()
//
//        // Then
//        #expect(mockTaskScheduler.registeredIdentifiers.count == 1)
//    }
//
//    @Test func start_sets_up_scheduler_only_once() {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//
//        // When
//        scheduler.start()
//        scheduler.start()
//        scheduler.start()
//
//        // Then
//        #expect(mockTaskScheduler.registeredIdentifiers.count == 1)
//    }
//
//    @Test func start_only_schedules_foreground_timers_for_both_context_work() {
//        // Given
//        let backgroundOnlyWork = MockBackgroundWork(identifier: "test.background", period: 60, executionContext: .backgroundOnly)
//        let bothContextWork = MockBackgroundWork(identifier: "test.both", period: 120, executionContext: .both)
//
//        // Create a fresh scheduler to avoid state pollution from other tests
//        let testUserDefaults = UserDefaults(suiteName: "start_only_schedules_foreground_timers_for_both_context_work")!
//        testUserDefaults.removePersistentDomain(forName: "start_only_schedules_foreground_timers_for_both_context_work")
//        let testTaskScheduler = MockBackgroundTaskScheduler()
//        let testTimerScheduler = MockTimerScheduler()
//        let testTimeProvider = MockTimeProvider()
//        let testScheduler = BackgroundWorkScheduler(
//            userDefaults: testUserDefaults,
//            taskScheduler: testTaskScheduler,
//            timerScheduler: testTimerScheduler,
//            timeProvider: testTimeProvider
//        )
//
//        testScheduler.register(backgroundOnlyWork)
//        testScheduler.register(bothContextWork)
//
//        // When
//        testScheduler.start()
//
//        // Then
//        #expect(testTaskScheduler.registeredIdentifiers.count == 2)
//        // Only .both work should have a foreground timer scheduled
//        #expect(testTimerScheduler.scheduledTimers.count == 1)
//        // Verify the timer is for the .both work by checking it's scheduled with correct interval
//        guard let timerInfo = testTimerScheduler.scheduledTimers.values.first else {
//            Issue.record("No timer scheduled")
//            return
//        }
//        #expect(timerInfo.interval == bothContextWork.period)
//    }
//
//    @Test func didEnterBackground_submits_background_task() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//        scheduler.start()
//        mockTaskScheduler.submittedRequests.removeAll()
//
//        // Verify foreground timer was scheduled initially
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//
//        // When
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        // Then
//        #expect(mockTaskScheduler.submittedRequests.count >= 1)
//        // Verify foreground timers were stopped
//        #expect(mockTimerScheduler.scheduledTimers.isEmpty)
//    }
//
//    @Test func willEnterForeground_cancels_background_tasks() {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//        scheduler.start()
//        mockTaskScheduler.cancelAllTaskRequestsCalled = false
//
//        // When
//        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
//
//        // Then
//        #expect(mockTaskScheduler.cancelAllTaskRequestsCalled)
//    }
//
//    @Test func submitNextBackgroundTask_selects_work_due_soonest() async {
//        // Given
//        let work1 = MockBackgroundWork(identifier: "test.work1", period: 120)
//        let work2 = MockBackgroundWork(identifier: "test.work2", period: 60)
//        scheduler.register(work1)
//        scheduler.register(work2)
//        scheduler.start()
//
//        // When
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        // Then
//        #expect(mockTaskScheduler.submittedRequests.last?.identifier == "test.work2")
//    }
//
//    @Test func submitNextBackgroundTask_uses_planned_run_date_for_calculation() async {
//        // Given
//        let work1 = MockBackgroundWork(identifier: "test.work1", period: 60)
//        let work2 = MockBackgroundWork(identifier: "test.work2", period: 120)
//        let now = Date()
//        let plannedRunDates: [String: Date] = ["test.work1": now.addingTimeInterval(10)]
//        savePlannedRunDates(plannedRunDates, to: userDefaults)
//        let testMockTimeProvider = MockTimeProvider(now: now)
//        let testMockTaskScheduler = MockBackgroundTaskScheduler()
//        let testMockTimerScheduler = MockTimerScheduler()
//        let testScheduler = BackgroundWorkScheduler(
//            userDefaults: userDefaults,
//            taskScheduler: testMockTaskScheduler,
//            timerScheduler: testMockTimerScheduler,
//            timeProvider: testMockTimeProvider
//        )
//        testScheduler.register(work1)
//        testScheduler.register(work2)
//        testScheduler.start()
//
//        // When
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            testMockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        // Then
//        #expect(testMockTaskScheduler.submittedRequests.last?.identifier == "test.work1")
//    }
//
//
//    @Test func plannedRunDates_load_from_persistence() async {
//        // Given
//        let now = Date()
//        let plannedDate = now.addingTimeInterval(15)
//        let plannedRunDates: [String: Date] = ["test.work": plannedDate]
//        savePlannedRunDates(plannedRunDates, to: userDefaults)
//        let testMockTimeProvider = MockTimeProvider(now: now)
//        let testMockTaskScheduler = MockBackgroundTaskScheduler()
//        let testMockTimerScheduler = MockTimerScheduler()
//        let testScheduler = BackgroundWorkScheduler(
//            userDefaults: userDefaults,
//            taskScheduler: testMockTaskScheduler,
//            timerScheduler: testMockTimerScheduler,
//            timeProvider: testMockTimeProvider
//        )
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        testScheduler.register(work)
//        testScheduler.start()
//
//        // When
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            testMockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        // Then
//        guard let submittedRequest = testMockTaskScheduler.submittedRequests.last as? BGAppRefreshTaskRequest else {
//            Issue.record("No request submitted")
//            return
//        }
//        let expectedNextRun = max(plannedDate, now)
//        let actualNextRun = submittedRequest.earliestBeginDate
//        #expect(actualNextRun == expectedNextRun)
//    }
//
//    @Test func plannedRunDates_follow_foreground_background_flow() async {
//        // Given
//        let start = Date(timeIntervalSince1970: 0)
//        mockTimeProvider.set(now: start)
//        mockTaskScheduler.onSubmit = nil
//        mockTaskScheduler.submittedRequests.removeAll()
//
//        let backgroundWork = MockBackgroundWork(
//            identifier: "test.background",
//            period: 30 * 60,
//            executionContext: .backgroundOnly
//        )
//        let bothContextWork = MockBackgroundWork(
//            identifier: "test.both",
//            period: 55 * 60,
//            executionContext: .both
//        )
//
//        scheduler.register(backgroundWork)
//        scheduler.register(bothContextWork)
//        scheduler.start()
//
//        // Initial baseline: only `.both` work gets a planned run date
//        var plannedDates = loadPlannedRunDates(from: userDefaults)
//        #expect(plannedDates[backgroundWork.identifier] == nil)
//        let expectedInitialBoth = mockTimeProvider.now().addingTimeInterval(bothContextWork.period)
//        #expect(plannedDates[bothContextWork.identifier] == expectedInitialBoth)
//
//        // Verify timer was scheduled for .both work
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//
//        // Advance 15 minutes and transition to background
//        mockTimeProvider.advance(by: 15 * 60)
//        let backgroundBaselineTime = mockTimeProvider.now()
//
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        plannedDates = loadPlannedRunDates(from: userDefaults)
//        let expectedBackgroundPlan = backgroundBaselineTime.addingTimeInterval(backgroundWork.period)
//        #expect(plannedDates[backgroundWork.identifier] == expectedBackgroundPlan)
//        #expect(plannedDates[bothContextWork.identifier] == expectedInitialBoth)
//
//        // Verify timers were stopped on background transition
//        #expect(mockTimerScheduler.scheduledTimers.isEmpty)
//
//        guard let firstRequest = mockTaskScheduler.submittedRequests.last as? BGAppRefreshTaskRequest else {
//            Issue.record("No background task request submitted")
//            return
//        }
//        #expect(firstRequest.identifier == backgroundWork.identifier)
//        #expect(firstRequest.earliestBeginDate == expectedBackgroundPlan)
//
//        mockTaskScheduler.onSubmit = nil
//        mockTaskScheduler.submittedRequests.removeAll()
//
//        // Advance another 15 minutes and return to foreground
//        mockTimeProvider.advance(by: 15 * 60)
//        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
//        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
//
//        plannedDates = loadPlannedRunDates(from: userDefaults)
//        #expect(plannedDates[backgroundWork.identifier] == expectedBackgroundPlan)
//        #expect(plannedDates[bothContextWork.identifier] == expectedInitialBoth)
//
//        // Timers should be scheduled again after returning to foreground
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//
//        // Advance until the foreground work is overdue and trigger immediate execution
//        mockTimeProvider.advance(by: 25 * 60)
//
//        // Clear timers since we're posting didBecomeActive which will reschedule
//        mockTimerScheduler.scheduledTimers.removeAll()
//
//        await withCheckedContinuation { @MainActor continuation in
//            bothContextWork.onExecute = { continuation.resume() }
//            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
//        }
//
//        plannedDates = loadPlannedRunDates(from: userDefaults)
//        let expectedBothAfterRun = mockTimeProvider.now().addingTimeInterval(bothContextWork.period)
//        #expect(bothContextWork.executeCallCount == 1)
//        #expect(plannedDates[bothContextWork.identifier] == expectedBothAfterRun)
//
//        mockTaskScheduler.onSubmit = nil
//        mockTaskScheduler.submittedRequests.removeAll()
//
//        // Background again to allow background-only work to run (now overdue)
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        guard let secondRequest = mockTaskScheduler.submittedRequests.last as? BGAppRefreshTaskRequest else {
//            Issue.record("No background task request submitted on second background transition")
//            return
//        }
//        #expect(secondRequest.identifier == backgroundWork.identifier)
//        #expect(secondRequest.earliestBeginDate == mockTimeProvider.now())
//
//        mockTaskScheduler.onSubmit = nil
//
//        guard let handler = mockTaskScheduler.registeredHandlers[backgroundWork.identifier] else {
//            Issue.record("Handler not registered")
//            return
//        }
//        let mockTask = MockBackgroundTask(identifier: backgroundWork.identifier)
//
//        await withCheckedContinuation { @MainActor continuation in
//            backgroundWork.onExecute = { continuation.resume() }
//            handler(mockTask)
//        }
//
//        plannedDates = loadPlannedRunDates(from: userDefaults)
//        let expectedBackgroundAfterRun = mockTimeProvider.now().addingTimeInterval(backgroundWork.period)
//        #expect(backgroundWork.executeCallCount == 1)
//        #expect(plannedDates[backgroundWork.identifier] == expectedBackgroundAfterRun)
//        #expect(plannedDates[bothContextWork.identifier] == expectedBothAfterRun)
//
//        mockTaskScheduler.submittedRequests.removeAll()
//    }
//
//    @Test func backgroundTask_executes_work() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//        scheduler.start()
//
//        // When
//        guard let handler = mockTaskScheduler.registeredHandlers["test.work"] else {
//            Issue.record("Handler not registered")
//            return
//        }
//        let mockTask = MockBackgroundTask(identifier: "test.work")
//
//        await withCheckedContinuation { @MainActor continuation in
//            work.onExecute = { continuation.resume() }
//            handler(mockTask)
//        }
//
//        // Then
//        #expect(work.executeCallCount == 1)
//        #expect(mockTask.setTaskCompletedCalled)
//        #expect(mockTask.lastSuccessValue == true)
//    }
//
//    @Test func backgroundTask_calls_didFail_on_work_failure() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        work.shouldSucceed = false
//        scheduler.register(work)
//        scheduler.start()
//
//        // When
//        guard let handler = mockTaskScheduler.registeredHandlers["test.work"] else {
//            Issue.record("Handler not registered")
//            return
//        }
//        let mockTask = MockBackgroundTask(identifier: "test.work")
//
//        await withCheckedContinuation { @MainActor continuation in
//            work.onDidFail = { _ in continuation.resume() }
//            handler(mockTask)
//        }
//
//        // Then
//        #expect(work.didFailCallCount == 1)
//        #expect(mockTask.lastSuccessValue == false)
//    }
//
//    @Test func backgroundTask_calls_didExpire_on_expiration() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//        scheduler.start()
//
//        let mockTask = MockBackgroundTask(identifier: "test.work")
//
//        await withCheckedContinuation { @MainActor continuation in
//            mockTask.onExpirationHandlerSet = { continuation.resume() }
//
//            // When
//            guard let handler = mockTaskScheduler.registeredHandlers["test.work"] else {
//                Issue.record("Handler not registered")
//                return
//            }
//            handler(mockTask)
//        }
//
//        mockTask.expirationHandler?()
//
//        // Then
//        #expect(work.didExpireCallCount == 1)
//    }
//
//    @Test func backgroundTask_schedules_next_task_after_completion() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60)
//        scheduler.register(work)
//        scheduler.start()
//        mockTaskScheduler.submittedRequests.removeAll()
//
//        // When
//        guard let handler = mockTaskScheduler.registeredHandlers["test.work"] else {
//            Issue.record("Handler not registered")
//            return
//        }
//        let mockTask = MockBackgroundTask(identifier: "test.work")
//
//        // The handler will call scheduleBackgroundTasks after completion, which submits a new task
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            handler(mockTask)
//        }
//
//        // Then
//        #expect(mockTaskScheduler.submittedRequests.count == 1)
//    }
//
//    // MARK: - Timer Execution Tests
//
//    @Test func foreground_timer_executes_work_when_fired() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60, executionContext: .both)
//        scheduler.register(work)
//        scheduler.start()
//
//        // Verify timer was scheduled
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//        #expect(work.executeCallCount == 0)
//
//        // When - Fire the timer
//        await withCheckedContinuation { @MainActor continuation in
//            work.onExecute = { continuation.resume() }
//            mockTimerScheduler.fireAllTimers()
//        }
//
//        // Then
//        #expect(work.executeCallCount == 1)
//        // Verify new timer was scheduled for next execution
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//    }
//
//    @Test func foreground_timer_updates_planned_date_after_execution() async {
//        // Given
//        let start = Date(timeIntervalSince1970: 1000)
//        mockTimeProvider.set(now: start)
//        let work = MockBackgroundWork(identifier: "test.work", period: 60, executionContext: .both)
//        scheduler.register(work)
//        scheduler.start()
//
//        let initialPlannedDate = loadPlannedRunDates(from: userDefaults)["test.work"]
//        #expect(initialPlannedDate == start.addingTimeInterval(60))
//
//        // When - Fire the timer
//        await withCheckedContinuation { @MainActor continuation in
//            work.onExecute = { continuation.resume() }
//            mockTimerScheduler.fireAllTimers()
//        }
//
//        // Then - Planned date should be updated to now + period
//        let updatedPlannedDate = loadPlannedRunDates(from: userDefaults)["test.work"]
//        #expect(updatedPlannedDate == start.addingTimeInterval(60))
//
//        // Verify new timer is scheduled with correct interval
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//        guard let timerInfo = mockTimerScheduler.scheduledTimers.values.first else {
//            Issue.record("No timer scheduled after execution")
//            return
//        }
//        #expect(timerInfo.interval == 60)
//    }
//
//    @Test func multiple_foreground_timers_execute_independently() async {
//        // Given
//        let work1 = MockBackgroundWork(identifier: "test.work1", period: 30, executionContext: .both)
//        let work2 = MockBackgroundWork(identifier: "test.work2", period: 60, executionContext: .both)
//        scheduler.register(work1)
//        scheduler.register(work2)
//        scheduler.start()
//
//        // Verify both timers are scheduled
//        #expect(mockTimerScheduler.scheduledTimers.count == 2)
//
//        // When - Fire only work1's timer
//        guard let timer1 = mockTimerScheduler.scheduledTimers.first(where: { $0.value.interval == 30 }) else {
//            Issue.record("Timer for work1 not found")
//            return
//        }
//
//        await withCheckedContinuation { @MainActor continuation in
//            work1.onExecute = { continuation.resume() }
//            let mockTimer = MockTimer(id: timer1.key, scheduler: mockTimerScheduler, block: timer1.value.block)
//            mockTimer.fire()
//        }
//
//        // Then - Only work1 should have executed
//        #expect(work1.executeCallCount == 1)
//        #expect(work2.executeCallCount == 0)
//    }
//
//    @Test func timer_execution_with_time_advancement() async {
//        // Given
//        let start = Date(timeIntervalSince1970: 1000)
//
//        // Create fresh instances to avoid state pollution
//        let testUserDefaults = UserDefaults(suiteName: "timer_execution_with_time_advancement")!
//        testUserDefaults.removePersistentDomain(forName: "timer_execution_with_time_advancement")
//        let testTimeProvider = MockTimeProvider(now: start)
//        let testTaskScheduler = MockBackgroundTaskScheduler()
//        let testTimerScheduler = MockTimerScheduler()
//        let testScheduler = BackgroundWorkScheduler(
//            userDefaults: testUserDefaults,
//            taskScheduler: testTaskScheduler,
//            timerScheduler: testTimerScheduler,
//            timeProvider: testTimeProvider
//        )
//
//        let work = MockBackgroundWork(identifier: "test.work", period: 60, executionContext: .both)
//        testScheduler.register(work)
//        testScheduler.start()
//
//        // Initial planned date
//        let initialPlanned = loadPlannedRunDates(from: testUserDefaults)["test.work"]
//        #expect(initialPlanned == start.addingTimeInterval(60))
//
//        // When - Advance time and fire timer
//        testTimeProvider.advance(by: 30)
//        let timeAfterAdvance = testTimeProvider.now()
//
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            work.onExecute = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            testTimerScheduler.fireAllTimers()
//        }
//
//        // Then - New planned date should be based on advanced time, not start time
//        let updatedPlanned = loadPlannedRunDates(from: testUserDefaults)["test.work"]
//        #expect(updatedPlanned == timeAfterAdvance.addingTimeInterval(60))
//    }
//
//    @Test func timers_invalidated_on_background_transition() async {
//        // Given
//        let work1 = MockBackgroundWork(identifier: "test.work1", period: 30, executionContext: .both)
//        let work2 = MockBackgroundWork(identifier: "test.work2", period: 60, executionContext: .both)
//        scheduler.register(work1)
//        scheduler.register(work2)
//        scheduler.start()
//
//        // Verify timers are scheduled
//        #expect(mockTimerScheduler.scheduledTimers.count == 2)
//
//        // When - Transition to background
//        await withCheckedContinuation { @MainActor continuation in
//            var resumed = false
//            mockTaskScheduler.onSubmit = {
//                guard !resumed else { return }
//                resumed = true
//                continuation.resume()
//            }
//            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
//        }
//
//        // Then - All timers should be invalidated
//        #expect(mockTimerScheduler.scheduledTimers.isEmpty)
//    }
//
//    @Test func foreground_timer_executes_overdue_work_immediately() async {
//        // Given
//        let start = Date(timeIntervalSince1970: 1000)
//        mockTimeProvider.set(now: start)
//        let work = MockBackgroundWork(identifier: "test.work", period: 60, executionContext: .both)
//
//        // Set a planned date in the past
//        let pastDate = start.addingTimeInterval(-30) // 30 seconds in the past
//        savePlannedRunDates(["test.work": pastDate], to: userDefaults)
//
//        scheduler.register(work)
//
//        // When - Start scheduler (should execute immediately because work is overdue)
//        await withCheckedContinuation { @MainActor continuation in
//            work.onExecute = { continuation.resume() }
//            scheduler.start()
//        }
//
//        // Then
//        #expect(work.executeCallCount == 1)
//        // New timer should be scheduled
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//        // Planned date should be updated
//        let updatedPlanned = loadPlannedRunDates(from: userDefaults)["test.work"]
//        #expect(updatedPlanned == start.addingTimeInterval(60))
//    }
//
//    @Test func foreground_timer_failure_still_reschedules() async {
//        // Given
//        let work = MockBackgroundWork(identifier: "test.work", period: 60, executionContext: .both)
//        work.shouldSucceed = false
//        scheduler.register(work)
//        scheduler.start()
//
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//
//        // When - Fire timer (work will fail)
//        await withCheckedContinuation { @MainActor continuation in
//            work.onExecute = { continuation.resume() }
//            mockTimerScheduler.fireAllTimers()
//        }
//
//        // Then - Even though work failed, timer should be rescheduled
//        #expect(work.executeCallCount == 1)
//        #expect(mockTimerScheduler.scheduledTimers.count == 1)
//    }
//
//    private func savePlannedRunDates(_ dates: [String: Date], to userDefaults: UserDefaults) {
//        if let encoded = try? JSONEncoder().encode(dates) {
//            userDefaults.set(encoded, forKey: "BackgroundWorkScheduler.plannedRunDates")
//        }
//    }
//
//    private func loadPlannedRunDates(from userDefaults: UserDefaults) -> [String: Date] {
//        guard let data = userDefaults.data(forKey: "BackgroundWorkScheduler.plannedRunDates"),
//              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
//            return [:]
//        }
//        return decoded
//    }
}

// MARK: - Mock Classes

private class MockBackgroundWork: BackgroundWork, @unchecked Sendable {
    let identifier: String
    let period: TimeInterval
    let executionContext: WorkExecutionContext
    var shouldSucceed = true

    var executeCallCount = 0
    var didFailCallCount = 0
    var didExpireCallCount = 0
    var lastError: Error?

    var onExecute: (() -> Void)?
    var onDidFail: ((Error) -> Void)?
    var onDidExpire: (() -> Void)?

    init(identifier: String, period: TimeInterval, executionContext: WorkExecutionContext = .both) {
        self.identifier = identifier
        self.period = period
        self.executionContext = executionContext
    }

    func execute() async throws {
        executeCallCount += 1
        onExecute?()
        if !shouldSucceed {
            throw MockError.executionFailed
        }
    }

    func didFail(with error: Error) async {
        didFailCallCount += 1
        lastError = error
        onDidFail?(error)
    }

    func didExpire() async {
        didExpireCallCount += 1
        onDidExpire?()
    }

    enum MockError: Error {
        case executionFailed
    }
}

fileprivate class MockBackgroundTaskScheduler: BackgroundTaskScheduling {
    var registeredIdentifiers: [String] = []
    var registeredHandlers: [String: (BackgroundTaskProtocol) -> Void] = [:]
    var submittedRequests: [BGTaskRequest] = []
    var cancelAllTaskRequestsCalled = false

    var onSubmit: (() -> Void)?

    func register(forTaskWithIdentifier identifier: String, using queue: DispatchQueue?, launchHandler: @escaping (BackgroundTaskProtocol) -> Void) {
        registeredIdentifiers.append(identifier)
        registeredHandlers[identifier] = launchHandler
    }

    func submit(_ taskRequest: BGTaskRequest) throws {
        submittedRequests.append(taskRequest)
        onSubmit?()
    }

    func cancelAllTaskRequests() {
        cancelAllTaskRequestsCalled = true
    }
}

private class MockBackgroundTask: BackgroundTaskProtocol {
    let identifier: String
    var expirationHandler: (() -> Void)? {
        didSet {
            onExpirationHandlerSet?()
        }
    }
    var setTaskCompletedCalled = false
    var lastSuccessValue: Bool?
    var onSetTaskCompleted: (() -> Void)?
    var onExpirationHandlerSet: (() -> Void)?

    init(identifier: String) {
        self.identifier = identifier
    }

    func setTaskCompleted(success: Bool) {
        setTaskCompletedCalled = true
        lastSuccessValue = success
        onSetTaskCompleted?()
    }
}

private final class MockTimeProvider: TimeProvider {
    private var currentDate: Date

    init(now: Date = Date()) {
        self.currentDate = now
    }

    func now() -> Date {
        currentDate
    }

    func set(now date: Date) {
        currentDate = date
    }

    func advance(by interval: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(interval)
    }
}

private final class MockTimerScheduler: TimerScheduling {
    var scheduledTimers: [String: (interval: TimeInterval, block: () -> Void)] = [:]
    var timerCount = 0

    func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> any TimerProtocol {
        let timerId = "timer_\(timerCount)"
        timerCount += 1
        scheduledTimers[timerId] = (interval, block)
        return MockTimer(id: timerId, scheduler: self, block: block)
    }

    func fireAllTimers() {
        for (_, timerInfo) in scheduledTimers {
            timerInfo.block()
        }
        scheduledTimers.removeAll()
    }

    func removeTimer(_ id: String) {
        scheduledTimers.removeValue(forKey: id)
    }
}

private final class MockTimer: TimerProtocol {
    let id: String
    weak var scheduler: MockTimerScheduler?
    let block: () -> Void

    init(id: String, scheduler: MockTimerScheduler, block: @escaping () -> Void) {
        self.id = id
        self.scheduler = scheduler
        self.block = block
    }

    func invalidate() {
        scheduler?.removeTimer(id)
    }

    func fire() {
        block()
    }
}
