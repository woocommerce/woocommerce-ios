import protocol Storage.StorageType
import Yosemite

/// Type that fetches the necessary resources when a push notification arrives in the background.
/// Current it fetches:
/// - Notifications
/// - Orders List (If needed)
/// - Notification Order (If needed)
///
struct PushNotificationBackgroundSynchronizer {

    /// Push notification user info
    ///
    private let userInfo: [AnyHashable: Any]

    private let stores: StoresManager

    private let storage: StorageType

    init(userInfo: [AnyHashable: Any], stores: StoresManager = ServiceLocator.stores, storage: StorageType = ServiceLocator.storageManager.viewStorage) {
        self.userInfo = userInfo
        self.stores = stores
        self.storage = storage
    }

    /// Starts the sync process
    ///
    @MainActor
    func sync() async -> UIBackgroundFetchResult {

        guard let pushNotification = PushNotification.from(userInfo: userInfo) else {
            return .noData
        }

        do {

            let startTime = Date.now

            // I'm not sure why we need to sync all notifications instead of only the current one.
            // This is legacy code copied from PushNotificationsManager
            try await synchronizeNotifications()

            // Find the orderID from the previously synced notification.
            guard let orderID = getOrderID(noteID: pushNotification.noteID) else {
                return .newData
            }

            // Sync the order list data
            try await OrderListSyncBackgroundTask(siteID: pushNotification.siteID, stores: stores).dispatch()

            // There is a change that the specific order was not fetched in the previous operation, specially if the user has some filters set.
            // In that case, specifically sync the notification order so it's available for the user when they tap the notification.
            if isOrderNotSynced(siteID: pushNotification.siteID, orderID: orderID) {
                try await synchronizeOrder(siteID: pushNotification.siteID, orderID: orderID)
            }

            let timeTaken = round(Date.now.timeIntervalSince(startTime))
            ServiceLocator.analytics.track(event: .BackgroundUpdates.orderPushNotificationSynced(timeTaken: timeTaken))

            return .newData

        } catch {
            DDLogError("⛔️ Error synchronizing notification dependencies: \(error)")
            ServiceLocator.analytics.track(event: .BackgroundUpdates.orderPushNotificationSyncError(error))
            return .noData
        }
    }

    /// Synchronizes all of the Notifications.
    ///
    @MainActor
    private func synchronizeNotifications() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let action = NotificationAction.synchronizeNotifications { error in
                DDLogInfo("📱 Finished Synchronizing Notifications!")
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            DDLogInfo("📱 Synchronizing Notifications...")
            stores.dispatch(action)
        }
    }

    /// Synchronizes an specific order.
    ///
    @MainActor
    private func synchronizeOrder(siteID: Int64, orderID: Int64) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = OrderAction.retrieveOrderRemotely(siteID: siteID, orderID: orderID) { result in
                DDLogInfo("📱 Finished Synchronizing Order \(orderID)!")
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            DDLogInfo("📱 Synchronizing Order \(orderID) ...")
            stores.dispatch(action)
        }
    }

    /// Tries to find the `orderID` of an already stored order note object.
    /// Returns `nil` if the note is not stored or of its not an order note.
    ///
    @MainActor
    private func getOrderID(noteID: Int64) -> Int64? {
        guard let note = storage.loadNotification(noteID: noteID)?.toReadOnly() else {
            return nil
        }

        guard let orderID = note.meta.identifier(forKey: .order), note.kind == .storeOrder else {
            return nil
        }

        return Int64(orderID)
    }

    /// Checks if an order does not exists  in our storage layer.
    ///
    @MainActor
    private func isOrderNotSynced(siteID: Int64, orderID: Int64) -> Bool {
        storage.loadOrder(siteID: siteID, orderID: orderID) == nil
    }
}
