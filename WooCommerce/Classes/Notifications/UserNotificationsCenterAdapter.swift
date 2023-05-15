import Foundation
import UserNotifications


/// UserNotificationsCenterAdapter: Wraps UNUserNotificationCenter API. Meant for Unit Testing Purposes.
///
protocol UserNotificationsCenterAdapter {

    /// Loads the Notifications Authorization Status
    ///
    func loadAuthorizationStatus(queue: DispatchQueue, completion: @escaping (_ status: UNAuthorizationStatus) -> Void)

    /// Requests Push Notifications Authorization
    ///
    func requestAuthorization(queue: DispatchQueue, includesProvisionalAuth: Bool, completion: @escaping (Bool) -> Void)

    /// Removes all push notifications that have been delivered or scheduled
    func removeAllNotifications()

    // The application's user notification settings
    func notificationSettings() async -> UNNotificationSettings

    // Notification requests that have been scheduled for a future time or location and are waiting for their trigger to fire
    func pendingNotificationRequests() async -> [UNNotificationRequest]

    // Notification categories can be used to choose which actions will be displayed on which notifications.
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)

    // Adds a notification request to be presented at a scheduled time.
    func add(_ request: UNNotificationRequest) async throws
}


// MARK: - UNUserNotificationCenter: UserNotificationsCenterAdapter Conformance
//
extension UNUserNotificationCenter: UserNotificationsCenterAdapter {

    /// Loads the Notifications Authorization Status
    ///
    func loadAuthorizationStatus(queue: DispatchQueue = .main, completion: @escaping (_ status: UNAuthorizationStatus) -> Void) {
        getNotificationSettings { settings in
            queue.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    /// Requests Push Notifications Authorization
    ///
    func requestAuthorization(queue: DispatchQueue = .main, includesProvisionalAuth: Bool, completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = includesProvisionalAuth ? [.badge, .sound, .alert, .provisional]: [.badge, .sound, .alert]
        requestAuthorization(options: options) { (allowed, _)  in
            queue.async {
                completion(allowed)
            }
        }
    }

    func removeAllNotifications() {
        removeAllDeliveredNotifications()
        removeAllPendingNotificationRequests()
    }
}
