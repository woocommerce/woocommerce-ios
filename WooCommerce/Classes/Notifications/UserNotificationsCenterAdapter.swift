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
    func requestAuthorization(queue: DispatchQueue, completion: @escaping (Bool) -> Void)

    /// Removes all push notifications that have been delivered or scheduled
    func removeAllNotifications()
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
    func requestAuthorization(queue: DispatchQueue = .main, completion: @escaping (Bool) -> Void) {
        requestAuthorization(options: [.badge, .sound, .alert]) { (allowed, _)  in
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
