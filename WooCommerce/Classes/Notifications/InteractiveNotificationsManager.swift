import Foundation
import UserNotifications


final class InteractiveNotificationsManager: NSObject {

    /// Returns the shared InteractiveNotificationsManager instance.
    ///
    static let shared = InteractiveNotificationsManager()

    /// Sets the delegate for User Notifications.
    ///
    /// This method should be called once during the app initialization process.
    ///
    func registerForUserNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        // -TODO: Set notification categories
    }
}


// MARK: - UNUserNotificationCenterDelegate Conformance
//
extension InteractiveNotificationsManager: UNUserNotificationCenterDelegate {

    /// This method is only called when the app is in the foreground and a push notification is received.
    ///
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        let userInfo = notification.request.content.userInfo as NSDictionary

        // If the app is open, and a Zendesk view is being shown, Zendesk will display an alert allowing the user to view the updated ticket.
        handleZendeskNotification(userInfo: userInfo)

        completionHandler([])
    }

    private func handleZendeskNotification(userInfo: NSDictionary) {
        if let type = userInfo.string(forKey: ZendeskManager.PushNotificationIdentifiers.key),
            type == ZendeskManager.PushNotificationIdentifiers.type,
        let payload = userInfo as? [AnyHashable : Any] {
            ZendeskManager.shared.handlePushNotification(payload)
        }
    }

    /// This method is only called when the app is in the background
    /// and the user tapped a remote push notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        // other notifications
        handleZendeskNotification(userInfo: userInfo)

        completionHandler()
    }
}
