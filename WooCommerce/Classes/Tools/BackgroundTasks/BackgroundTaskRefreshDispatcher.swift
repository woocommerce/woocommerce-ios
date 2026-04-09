import UIKit
import Foundation
import BackgroundTasks
import Network

final class BackgroundTaskRefreshDispatcher {
    enum BackgroundTaskType: Codable, CaseIterable {
        case ordersAndDashboardSync
        case posCatalogSync
    }

    private let schedule = BackgroundTaskSchedule()

    /// Schedule the app refresh background task.
    ///
    func scheduleAppRefresh() {
        for taskType in BackgroundTaskType.allCases {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskType.identifier)
        }
        schedule.setDefaultPreferredTaskDates()
        scheduleNextTask()
    }

    /// Schedules a next background task using a BackgroundTaskSchedule
    /// Sets earliestBeginDate to nil (no delay) if preferred run date is in the past
    ///
    private func scheduleNextTask() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1) else {
            scheduleTask(type: .ordersAndDashboardSync, earliestBeginDate: Date(timeIntervalSinceNow: 30 * 60))
            return
        }

        let nextTask = schedule.getNextTask()
        let preferredDate = schedule.preferredRunDate(for: nextTask)
        let earliestBeginDate = preferredDate > Date() ? preferredDate : nil
        scheduleTask(type: nextTask, earliestBeginDate: earliestBeginDate)
    }

    /// Schedules a background task with the specified type and timing.
    ///
    /// - Parameters:
    ///   - type: The type of background task to schedule.
    ///   - earliestBeginDate: The earliest date at which the task can begin. When `nil`, the task can be submitted right away.
    private func scheduleTask(type: BackgroundTaskType, earliestBeginDate: Date?) {
        // Do not run this code while running test because this framework is not enabled in the simulator
        guard Self.isNotRunningTests() else {
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: type.identifier)
        request.earliestBeginDate = earliestBeginDate
        do {
            DDLogInfo("Scheduling background refresh task \(type) in \(Int(earliestBeginDate?.timeIntervalSinceNow ?? 0))s")
            try BGTaskScheduler.shared.submit(request)
        } catch {
            DDLogError("⛔️ Could not schedule \(type) task: \(error)")
        }
    }

    /// Registers a closure to be invoked when the system wants to perform a background task.
    ///
    func registerSystemTaskIdentifier() {

        // Do not run this code while running test because this framework is not enabled in the simulator
        guard Self.isNotRunningTests() else {
            return
        }

        // Registers handlers for all task types.
        for taskType in BackgroundTaskType.allCases {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: taskType.identifier, using: nil) { [weak self] task in
                guard let refreshTask = task as? BGAppRefreshTask else {
                    return
                }
                self?.handleBackgroundTask(refreshTask, type: taskType)
            }
        }

        if UIApplication.shared.backgroundRefreshStatus != .available {
            ServiceLocator.analytics.track(event: .BackgroundUpdates.disabled())
        }
    }

    /// Routes background task to appropriate handler based on type.
    ///
    private func handleBackgroundTask(_ backgroundTask: BGAppRefreshTask, type: BackgroundTaskType) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            backgroundTask.setTaskCompleted(success: false)
            return
        }

        // Make sure the next task is scheduled
        schedule.setNextPreferredRunDate(for: type)
        scheduleNextTask()

        switch type {
        case .ordersAndDashboardSync:
            handleOrdersAndDashboardSync(backgroundTask: backgroundTask, siteID: siteID)
        case .posCatalogSync:
            handlePOSCatalogSync(backgroundTask: backgroundTask, siteID: siteID)
        }
    }

    /// Handles orders and dashboard sync.
    ///
    private func handleOrdersAndDashboardSync(backgroundTask: BGAppRefreshTask, siteID: Int64) {
        // Launch all refresh tasks in parallel.
        let refreshTasks = Task {
            do {
                async let systemInfo = BackgroundTaskSystemInfo()

                let startTime = Date.now

                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await OrderListSyncBackgroundTask(siteID: siteID).dispatch()
                    }
                    group.addTask {
                        try await DashboardSyncBackgroundTask(siteID: siteID).dispatch()
                    }

                    // Rethrows error
                    for try await _ in group {
                        // No-op
                    }
                }

                let timeTaken = round(Date.now.timeIntervalSince(startTime))

                var timeSinceLastRun: TimeInterval? = nil
                if let lastRunTime = UserDefaults.standard[.lastBackgroundRefreshCompletionTime] as? Date {
                    timeSinceLastRun = round(lastRunTime.timeIntervalSinceNow.magnitude)
                }

                await ServiceLocator.analytics.track(event: .BackgroundUpdates.dataSynced(
                    timeTaken: timeTaken,
                    backgroundTimeGranted: systemInfo.backgroundTimeGranted,
                    networkType: systemInfo.networkType,
                    isExpensiveConnection: systemInfo.isExpensiveConnection,
                    isLowDataMode: systemInfo.isLowDataMode,
                    isPowered: systemInfo.isPowered,
                    batteryLevel: systemInfo.batteryLevel,
                    isLowPowerMode: systemInfo.isLowPowerMode,
                    timeSinceLastRun: timeSinceLastRun
                ))

                // Save date, for use in analytics next time we refresh
                UserDefaults.standard[.lastBackgroundRefreshCompletionTime] = Date.now

                backgroundTask.setTaskCompleted(success: true)

            } catch {
                ServiceLocator.analytics.track(event: .BackgroundUpdates.dataSyncError(error))
                backgroundTask.setTaskCompleted(success: false)
            }
        }

        // Provide the background task with an expiration handler that cancels the operation.
        backgroundTask.expirationHandler = {

            ServiceLocator.analytics.track(event: .BackgroundUpdates.dataSyncError(BackgroundError.expired))
            refreshTasks.cancel()
        }
    }

    /// Handles POS catalog sync refresh task.
    ///
    // TODO: WOOMOB-1677 - This background refresh needs to handle in-progress catalog generation.
    // Currently, if generation was started in a previous session, this will just start a full sync
    // again. Instead, we should:
    // 1. Check if there's an in-progress generation (requires state persistence)
    // 2. Poll once for the generation status within the ~30s background window
    // 3. Download and parse if ready, or save state and wait for next refresh
    // This should also check on foreground app opens, not just background refresh.
    private func handlePOSCatalogSync(backgroundTask: BGAppRefreshTask, siteID: Int64) {
        guard let coordinator = ServiceLocator.stores.posCatalogSyncCoordinator else {
            DDLogInfo("POS catalog sync background refresh skipped: Feature flag disabled or logged out")
            backgroundTask.setTaskCompleted(success: false)
            return
        }

        let syncTask = Task {
            do {
                try await coordinator.performSmartSync(for: siteID)
                backgroundTask.setTaskCompleted(success: true)
            } catch {
                DDLogError("⛔️ POS catalog sync background refresh failed: \(error)")
                backgroundTask.setTaskCompleted(success: false)
            }
        }

        backgroundTask.expirationHandler = {
            DDLogError("⛔️ POS catalog sync background refresh expired")
            syncTask.cancel()
            backgroundTask.setTaskCompleted(success: false)
        }
    }
}

private extension BackgroundTaskRefreshDispatcher {
    static func isNotRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") == nil
    }
}

/// To easily track expired background time error.
///
extension BackgroundTaskRefreshDispatcher {
    private enum BackgroundError: Error {
        case expired
    }
}

// MARK: - Background Task Type Helpers

fileprivate extension BackgroundTaskRefreshDispatcher.BackgroundTaskType {
    /// System background task identifier. Should match the info.plist value.
    var identifier: String {
        switch self {
        case .ordersAndDashboardSync:
            return "com.automattic.woocommerce.refresh"
        case .posCatalogSync:
            return "com.automattic.woocommerce.refresh.pos.catalog.sync"
        }
    }
}

// MARK: - System Information Helper

private struct NetworkInfo {
    let type: String
    let isExpensive: Bool
    let isLowDataMode: Bool
}

private struct BackgroundTaskSystemInfo {
    let backgroundTimeGranted: TimeInterval?
    private let networkInfo: NetworkInfo
    let isPowered: Bool
    let batteryLevel: Float
    let isLowPowerMode: Bool

    // Computed properties for clean external access
    var networkType: String { networkInfo.type }
    var isExpensiveConnection: Bool { networkInfo.isExpensive }
    var isLowDataMode: Bool { networkInfo.isLowDataMode }

    @MainActor
    init() async {
        // Background time granted (nil if foreground/unlimited)
        let backgroundTime = UIApplication.shared.backgroundTimeRemaining
        self.backgroundTimeGranted = backgroundTime < Double.greatestFiniteMagnitude ? backgroundTime : nil

        // Network info
        self.networkInfo = await Self.getNetworkInfo()

        // Power and battery info
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        self.isPowered = device.batteryState == .charging || device.batteryState == .full
        self.batteryLevel = device.batteryLevel
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        device.isBatteryMonitoringEnabled = false
    }

    private static func getNetworkInfo() async -> NetworkInfo {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "network.monitor.queue")

        let (stream, continuation) = AsyncStream.makeStream(of: NWPath.self)

        monitor.pathUpdateHandler = { path in
            continuation.yield(path)
        }

        monitor.start(queue: queue)

        defer {
            continuation.finish()
            monitor.cancel()
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
            continuation.finish()
        }

        if let path = await stream.first(where: { _ in true }) {
            timeoutTask.cancel()
            return NetworkInfo(path: path)
        } else {
            // Fallback in case no path is received.
            return NetworkInfo(type: "unknown", isExpensive: false, isLowDataMode: false)
        }
    }
}

private extension NetworkInfo {
    init(path: NWPath) {
        guard path.status == .satisfied else {
            self.type = "no_connection"
            self.isExpensive = false
            self.isLowDataMode = false
            return
        }

        self.type = Self.networkType(from: path)
        self.isExpensive = path.isExpensive
        self.isLowDataMode = path.isConstrained
    }

    private static func networkType(from path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "wifi"
        } else if path.usesInterfaceType(.cellular) {
            return "cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "ethernet"
        } else if path.usesInterfaceType(.loopback) {
            return "loopback"
        } else {
            return "other"
        }
    }
}
