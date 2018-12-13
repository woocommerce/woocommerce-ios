import Foundation


/// SupportManagerAdapter: Wraps the ZendeskManager API. Meant for Unit Testing Purposes.
///
protocol SupportManagerAdapter {

    /// Executed whenever the app receives a Push Notifications Token.
    ///
    func deviceTokenWasReceived(deviceToken: String)

    /// Executed whenever the app should unregister for Remote Notifications.
    ///
    func unregisterForRemoteNotifications()

    /// Executed whenever the app receives a Remote Notification.
    ///
    func pushNotificationReceived()

    /// Executed whenever the a user has tapped on a Remote Notification.
    ///
    func handlePushNotification(_ userInfo: [AnyHashable: Any])
}
