import Foundation
import BackgroundTasks

final class BackgroundTaskRefreshDispatcher {

    // System background task identifier. Should match the info.plist value.
    static let taskIdentifier = "com.automattic.woocommerce.refresh"

    /// Schedule the app refresh background task.
    ///
    func scheduleAppRefresh() {
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
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                return
            }
            self.handleAppRefresh(backgroundTask: refreshTask)
        }
    }

    /// Handle the app specific tasks to be performed with an app refresh background task.
    ///
    private func handleAppRefresh(backgroundTask: BGAppRefreshTask) {

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        // Schedule a new refresh task.
        scheduleAppRefresh()

        let ordersSyncTask = OrderSyncBackgroundTask(siteID: siteID, backgroundTask: backgroundTask).dispatch()

        // Provide the background task with an expiration handler that cancels the operation.
        backgroundTask.expirationHandler = {
            ordersSyncTask.cancel()
        }
     }
}
