import Foundation
import UserNotifications
@testable import WooCommerce


/// MockUserNotificationsCenterAdapter: UNUserNotificationCenter Mock
///
final class MockUserNotificationsCenterAdapter: UserNotificationsCenterAdapter {

    /// User Notifications Authorization Status
    ///
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var settingsCoder = MockNSCoder()

    private(set) var notificationCategories: Set<UNNotificationCategory> = []

    private var notificationRequests: [UNNotificationRequest] = []

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
    func requestAuthorization(queue: DispatchQueue, includesProvisionalAuth: Bool, completion: @escaping (Bool) -> Void) {
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

    func notificationSettings() async -> UNNotificationSettings {
        UNNotificationSettings(coder: settingsCoder)!
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        notificationRequests
    }

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        notificationCategories = categories
    }

    func add(_ request: UNNotificationRequest) async throws {
        notificationRequests.append(request)
    }
}

/// Mock coder to initialize UNNotificationSettings
///
final class MockNSCoder: NSCoder {
    var authorizationStatus = UNAuthorizationStatus.authorized.rawValue

    override func decodeInt64(forKey key: String) -> Int64 {
        return Int64(authorizationStatus)
    }

    override func decodeBool(forKey key: String) -> Bool {
        return true
    }
}
