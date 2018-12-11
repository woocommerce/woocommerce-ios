import Foundation


/// SupportManagerAdapter: Wraps the ZendeskManager API. Meant for Unit Testing Purposes.
///
protocol SupportManagerAdapter {

    /// Executed whenever the app should register a given DeviceToken for Push Notifications.
    ///
    func registerDeviceToken(_ deviceToken: String)

    /// Executed whenever the app should unregister for Remote Notifications.
    ///
    func unregisterForRemoteNotifications()
}


// MARK: - ZendeskManager: SupportManagerAdapter Conformance
//
extension ZendeskManager: SupportManagerAdapter { }
