import Foundation
import UIKit
import BackgroundTasks
import WooFoundation

/// Coordinates background work scheduling in foreground and background contexts.
///
/// Maintains a planned run date for each work item so that foreground/background
/// transitions preserve the remaining time until the next execution.
@MainActor
final class BackgroundWorkScheduler {
    private var registeredWork: [String: BackgroundWork] = [:]
    private var foregroundTimers: [String: Timer] = [:]
    private var plannedRunDates: [String: Date] {
        get { loadPlannedRunDates() }
        set { savePlannedRunDates(newValue) }
    }
    private var lifecycleObservers: [NSObjectProtocol] = []

    private let userDefaults: UserDefaults
    private let taskScheduler: BackgroundTaskScheduling
    private let timeProvider: TimeProvider

    init(userDefaults: UserDefaults = .standard,
         taskScheduler: BackgroundTaskScheduling = SystemBackgroundTaskScheduler(),
         timeProvider: TimeProvider = DefaultTimeProvider()) {
        self.userDefaults = userDefaults
        self.taskScheduler = taskScheduler
        self.timeProvider = timeProvider
        self.plannedRunDates = loadPlannedRunDates()
    }

    // MARK: - Registration

    func register(_ work: BackgroundWork) {
        registeredWork[work.identifier] = work

        taskScheduler.register(
            forTaskWithIdentifier: work.identifier,
            using: nil
        ) { [weak self] bgTask in
            guard let self else {
                return
            }

            Task { @MainActor in
                await self.handleBackgroundTask(bgTask, workIdentifier: work.identifier)
            }
        }

        DDLogInfo("[BackgroundWork] Registered work \(work.identifier)")
    }

    func start() {
        stopForegroundScheduling()
        removeLifecycleObservers()
        registerLifecycleObservers()

        if UIApplication.shared.applicationState == .background {
            scheduleBackgroundTasks()
        } else {
            startForegroundScheduling()
        }
    }

    // MARK: - Lifecycle Management

    private func startForegroundScheduling() {
        stopForegroundScheduling()
        baselineForegroundPlannedDates()

        DDLogInfo("[BackgroundWork] Starting foreground scheduling")

        for work in registeredWork.values where work.executionContext == .both {
            scheduleForegroundTimer(for: work)
        }
    }

    private func stopForegroundScheduling() {
        guard !foregroundTimers.isEmpty else {
            return
        }

        DDLogInfo("[BackgroundWork] Stopping foreground scheduling")

        for timer in foregroundTimers.values {
            timer.invalidate()
        }
        foregroundTimers.removeAll()
    }

    private func scheduleBackgroundTasks() {
        DDLogInfo("[BackgroundWork] Scheduling background tasks")
        baselineBackgroundPlannedDates()

        Task { await submitNextBackgroundTask() }
    }

    private func handleForegroundTransition() {
        DDLogInfo("[BackgroundWork] Handling foreground transition")
        taskScheduler.cancelAllTaskRequests()
    }

    // MARK: - Background Task Submission

    private func submitNextBackgroundTask() async {
        guard let nextWork = selectNextWork() else {
            DDLogWarn("[BackgroundWork] No work available to schedule")
            return
        }

        let plannedDate = plannedRunDate(for: nextWork)
        let nextRunDate = max(plannedDate, timeProvider.now())
        let request = BGAppRefreshTaskRequest(identifier: nextWork.identifier)
        request.earliestBeginDate = nextRunDate

        let delay = nextRunDate.timeIntervalSinceNow
        DDLogInfo("[BackgroundWork] Scheduling \(nextWork.identifier) in \(Int(delay))s")

        do {
            try taskScheduler.submit(request)
            DDLogInfo("[BackgroundWork] Scheduled background task \(nextWork.identifier)")
        } catch {
            DDLogError("[BackgroundWork] Failed to schedule \(nextWork.identifier): \(error)")
        }
    }

    private func selectNextWork() -> BackgroundWork? {
        return registeredWork.values.min { lhs, rhs in
            plannedRunDate(for: lhs) < plannedRunDate(for: rhs)
        }
    }

    private func plannedRunDate(for work: BackgroundWork) -> Date {
        if let plannedDate = plannedRunDates[work.identifier] {
            return plannedDate
        }

        let date = timeProvider.now().addingTimeInterval(work.period)
        plannedRunDates[work.identifier] = date
        return date
    }

    // MARK: - Foreground Timer Management

    private func scheduleForegroundTimer(for work: BackgroundWork) {
        let plannedDate = plannedRunDate(for: work)
        let delay = plannedDate.timeIntervalSinceNow

        if delay <= 0 {
            DDLogInfo("[BackgroundWork] \(work.identifier) overdue by \(Int(abs(delay)))s – executing immediately")
            Task { @MainActor in
                await self.executeWork(work, source: "foreground-immediate")
                self.scheduleForegroundTimer(for: work)
            }
            return
        }

        DDLogInfo("[BackgroundWork] Scheduling foreground timer for \(work.identifier) in \(Int(delay))s")

        let timer = timeProvider.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.foregroundTimers[work.identifier] = nil
                await self.executeWork(work, source: "foreground-timer")
                self.scheduleForegroundTimer(for: work)
            }
        }

        foregroundTimers[work.identifier] = timer
    }

    // MARK: - Background Task Handler

    private func handleBackgroundTask(_ bgTask: BackgroundTaskProtocol, workIdentifier: String) async {
        DDLogInfo("[BackgroundWork] Background task triggered for \(workIdentifier)")

        guard let work = registeredWork[workIdentifier] else {
            DDLogError("[BackgroundWork] Work not found: \(workIdentifier)")
            bgTask.setTaskCompleted(success: false)
            return
        }

        let executionTask = Task { await self.executeWork(work, source: "background") }

        bgTask.expirationHandler = { [weak self] in
            DDLogWarn("[BackgroundWork] Background task expired: \(workIdentifier)")
            executionTask.cancel()
            Task { @MainActor [weak self] in
                work.didExpire()
                bgTask.setTaskCompleted(success: false)
                self?.scheduleBackgroundTasks()
            }
        }

        let result = await executionTask.value

        if executionTask.isCancelled {
            return
        }

        if case .failure(let error) = result {
        }

        switch result {
        case .success:
            bgTask.setTaskCompleted(success: true)
        case .failure(let error):
            work.didFail(with: error)
            bgTask.setTaskCompleted(success: false)
        }

        scheduleBackgroundTasks()
    }

    // MARK: - Work Execution

    @discardableResult
    private func executeWork(_ work: BackgroundWork, source: String) async -> WorkExecutionResult {
        let workId = work.identifier

        DDLogInfo("[BackgroundWork] Starting \(workId) (source: \(source))")

        do {
            try await work.execute()
            updatePlannedRunDate(for: workId, to: timeProvider.now().addingTimeInterval(work.period))
            DDLogInfo("[BackgroundWork] \(workId) completed successfully")
            return .success
        } catch {
            updatePlannedRunDate(for: workId, to: timeProvider.now().addingTimeInterval(work.period))
            DDLogError("[BackgroundWork] \(workId) failed: \(error)")
            return .failure(error)
        }
    }

    // MARK: - Planned Date Management

    /// Baselines planned dates for `.both` work items when app launches or returns to foreground.
    /// Uses min(existing, now + period) to preserve any existing countdown from previous session.
    private func baselineForegroundPlannedDates() {
        let now = timeProvider.now()

        for work in registeredWork.values where work.executionContext == .both {
            let candidate = now.addingTimeInterval(work.period)
            if let existing = plannedRunDates[work.identifier] {
                if candidate < existing {
                    plannedRunDates[work.identifier] = candidate
                }
            } else {
                plannedRunDates[work.identifier] = candidate
            }
        }
    }

    /// Baselines planned dates for `.backgroundOnly` work items when app enters background.
    /// Only sets the date if it's nil (first time entering background since launch).
    private func baselineBackgroundPlannedDates() {
        let now = timeProvider.now()

        for work in registeredWork.values where work.executionContext == .backgroundOnly {
            if plannedRunDates[work.identifier] == nil {
                plannedRunDates[work.identifier] = now.addingTimeInterval(work.period)
            }
        }
    }

    private func updatePlannedRunDate(for identifier: String, to date: Date) {
        plannedRunDates[identifier] = date
    }

    // MARK: - State Persistence

    private func loadPlannedRunDates() -> [String: Date] {
        guard let data = userDefaults.data(forKey: "BackgroundWorkScheduler.plannedRunDates"),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func savePlannedRunDates(_ newValue: [String: Date]) {
        if let encoded = try? JSONEncoder().encode(newValue) {
            userDefaults.set(encoded, forKey: "BackgroundWorkScheduler.plannedRunDates")
        }
    }

    // MARK: - Helpers

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default

        let enterBackground = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.stopForegroundScheduling()
            self.baselineBackgroundPlannedDates()
            self.scheduleBackgroundTasks()
        }

        let willEnterForeground = center.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleForegroundTransition()
        }

        let didBecomeActive = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startForegroundScheduling()
        }

        lifecycleObservers.append(contentsOf: [enterBackground, willEnterForeground, didBecomeActive])
    }

    private func removeLifecycleObservers() {
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
    }
}

private enum WorkExecutionResult: Sendable {
    case success
    case failure(Error)
}
