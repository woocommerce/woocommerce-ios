import UIKit
import Foundation
import BackgroundTasks
import Network

final class BackgroundTaskRefreshDispatcher {

    // System background task identifier. Should match the info.plist value.
    static let taskIdentifier = "com.automattic.woocommerce.refresh"

    /// Schedule the app refresh background task.
    ///
    func scheduleAppRefresh() {

        // Do not run this code while running test because this framework is not enabled in the simulator
        guard Self.isNotRunningTests() else {
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // Fetch no earlier than 30 minutes from now.
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            DDLogError("⛔️ Could not schedule app refresh: \(error)")
        }
    }

    /// Registers a closure to be invoked when the system wants to perform a background task.
    ///
    func registerSystemTaskIdentifier() {

        // Do not run this code while running test because this framework is not enabled in the simulator
        guard Self.isNotRunningTests() else {
            return
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                return
            }
            self.handleAppRefresh(backgroundTask: refreshTask)
        }

        if UIApplication.shared.backgroundRefreshStatus != .available {
            ServiceLocator.analytics.track(event: .BackgroundUpdates.disabled())
        }
    }

    /// Handle the app specific tasks to be performed with an app refresh background task.
    ///
    private func handleAppRefresh(backgroundTask: BGAppRefreshTask) {

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        // Capture system state at start
        let systemInfo = BackgroundTaskSystemInfo()
        let lastRunTime = UserDefaults.standard[.lastBackgroundRefreshTime] as? Date

        // Schedule a new refresh task.
        scheduleAppRefresh()

        // Launch all refresh tasks in parallel.
        let refreshTasks = Task {
            do {

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
                        // No=op
                    }
                }

                let timeTaken = round(Date.now.timeIntervalSince(startTime))
                let timeSinceLastRun = lastRunTime?.timeIntervalSinceNow.magnitude

                // Track detailed analytics
                ServiceLocator.analytics.track(event: .BackgroundUpdates.dataSyncedDetailed(
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

                // Update last run timestamp
                UserDefaults.standard[.lastBackgroundRefreshTime] = Date()

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

// MARK: - System Information Helper

private struct NetworkInfo {
    let type: String
    let isExpensive: Bool
    let isLowDataMode: Bool
}

private struct BackgroundTaskSystemInfo {
    let backgroundTimeGranted: TimeInterval?
    let networkInfo: NetworkInfo
    let isPowered: Bool
    let batteryLevel: Float
    let isLowPowerMode: Bool

    // Computed properties for clean external access
    var networkType: String { networkInfo.type }
    var isExpensiveConnection: Bool { networkInfo.isExpensive }
    var isLowDataMode: Bool { networkInfo.isLowDataMode }

    init() {
        // Background time granted (nil if foreground/unlimited)
        let bgTime = UIApplication.shared.backgroundTimeRemaining
        self.backgroundTimeGranted = bgTime < Double.greatestFiniteMagnitude ? bgTime : nil

        // Network info
        self.networkInfo = Self.getNetworkInfo()

        // Power and battery info
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        self.isPowered = device.batteryState == .charging || device.batteryState == .full
        self.batteryLevel = device.batteryLevel
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        device.isBatteryMonitoringEnabled = false
    }

    private static func getNetworkInfo() -> NetworkInfo {
        // Use a semaphore to wait for the path update
        let semaphore = DispatchSemaphore(value: 0)
        let monitor = NWPathMonitor()
        var networkInfo = NetworkInfo(type: "no_connection", isExpensive: false, isLowDataMode: false)
        
        monitor.pathUpdateHandler = { path in
            // Check connection status first
            guard path.status == .satisfied else {
                networkInfo = NetworkInfo(type: "no_connection", isExpensive: false, isLowDataMode: false)
                semaphore.signal()
                return
            }
            
            let isExpensive = path.isExpensive
            let isLowDataMode = path.isConstrained
            
            // Determine connection type
            let networkType: String
            if path.usesInterfaceType(.wifi) {
                networkType = "wifi"
            } else if path.usesInterfaceType(.cellular) {
                networkType = "cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkType = "ethernet"
            } else if path.usesInterfaceType(.loopback) {
                networkType = "loopback"
            } else {
                networkType = "other"
            }
            
            networkInfo = NetworkInfo(type: networkType, isExpensive: isExpensive, isLowDataMode: isLowDataMode)
            semaphore.signal()
        }
        
        let queue = DispatchQueue(label: "network.monitor.queue")
        monitor.start(queue: queue)
        
        // Wait up to 1 second for network info
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        
        return networkInfo
    }
}
