import XCTest
@testable import WooCommerce


/// MockSupportManager: SupportManagerAdapter Mock
///
class MockSupportManager: SupportManagerAdapter {

    /// All of the tokens received via `registerDeviceToken`
    ///
    var registeredDeviceTokens = [String]()

    /// Indicates if `unregisterForRemoteNotifications` was executed
    ///
    var unregisterWasCalled = false

    /// Executed whenever the app receives a Push Notifications Token.
    ///
    func deviceTokenWasReceived(deviceToken: String) {
        registeredDeviceTokens.append(deviceToken)
    }

    /// Executed whenever the app should unregister for Remote Notifications.
    ///
    func unregisterForRemoteNotifications() {
        unregisterWasCalled = true
    }

    /// Executed whenever the app receives a Remote Notification.
    ///
    func pushNotificationReceived() { }

    /// Executed whenever the a user has tapped on a Remote Notification.
    ///
    func displaySupportRequest(using userInfo: [AnyHashable: Any]) { }
}
