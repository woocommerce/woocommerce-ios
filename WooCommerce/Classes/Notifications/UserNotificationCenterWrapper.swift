import Foundation
import UserNotifications


/// UserNotificationCenterWrapper: Wraps UNUserNotificationCenter API. Meant for Unit Testing Purposes.
///
protocol UserNotificationCenterWrapper {

    /// Loads the Notifications Authorization Status
    ///
    func loadAuthorizationStatus(queue: DispatchQueue, completion: @escaping (_ status: UNAuthorizationStatus) -> Void)

    /// Requests Push Notifications Authorization
    ///
    func requestAuthorization(queue: DispatchQueue, completion: @escaping (Bool) -> Void)
}


// MARK: - UNUserNotificationCenter: Wrapper COnformance
//
extension UNUserNotificationCenter: UserNotificationCenterWrapper {

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
}
