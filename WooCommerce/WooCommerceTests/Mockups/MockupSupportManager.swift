import XCTest
@testable import WooCommerce


/// MockupSupportManager: SupportManagerAdapter Mockup
///
class MockupSupportManager: SupportManagerAdapter {

    /// All of the tokens received via `registerDeviceToken`
    ///
    var registeredDeviceTokens = [String]()

    /// Indicates if `unregisterForRemoteNotifications` was executed
    ///
    var unregisterWasCalled = false

    /// Executed whenever the app should register a given DeviceToken for Push Notifications.
    ///
    func registerDeviceToken(_ deviceToken: String) {
        registeredDeviceTokens.append(deviceToken)
    }

    /// Executed whenever the app should unregister for Remote Notifications.
    ///
    func unregisterForRemoteNotifications() {
        unregisterWasCalled = true
    }
}
