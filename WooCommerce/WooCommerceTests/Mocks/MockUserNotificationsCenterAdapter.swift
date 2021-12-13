import Foundation
import UserNotifications
@testable import WooCommerce


/// MockUserNotificationsCenterAdapter: UNUserNotificationCenter Mock
///
final class MockUserNotificationsCenterAdapter: UserNotificationsCenterAdapter {

    /// User Notifications Authorization Status
    ///
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Indicates if `requestAuthorization` was called
    ///
    var requestAuthorizationWasCalled = false

    /// Indicates the Bool value that `requestAuthorization` should return
    ///
    var requestAuthorizationIsSuccessful = false

    /// Indicates if `removeAllNotifications` was called
    ///
    var removeAllNotificationsWasCalled = false

    /// "Simulates" an UNUserNotificationCenter Load Status OP
    ///
    func loadAuthorizationStatus(queue: DispatchQueue, completion: @escaping (_ status: UNAuthorizationStatus) -> Void) {
        completion(authorizationStatus)
    }

    /// "Simulates" a UNUserNotificationCenter Status Request OP
    ///
    func requestAuthorization(queue: DispatchQueue, completion: @escaping (Bool) -> Void) {
        requestAuthorizationWasCalled = true
        completion(requestAuthorizationIsSuccessful)
    }

    func removeAllNotifications() {
        removeAllNotificationsWasCalled = true
    }

    /// Restores the initial state
    ///
    func reset() {
        authorizationStatus = .notDetermined
        requestAuthorizationWasCalled = false
        requestAuthorizationIsSuccessful = false
    }
}
