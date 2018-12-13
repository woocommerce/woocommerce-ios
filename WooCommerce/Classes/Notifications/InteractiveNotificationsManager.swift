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
        // -TODO: check to see if alert display is still true, since we have the latest ZD SDK.
        let _ = handleZendeskNotification(userInfo: userInfo)

        completionHandler([])
    }

    private func handleZendeskNotification(userInfo: NSDictionary) -> Bool {
        if let type = userInfo.string(forKey: ZendeskManager.PushNotificationIdentifiers.key),
            type == ZendeskManager.PushNotificationIdentifiers.type,
        let payload = userInfo as? [AnyHashable : Any] {
            ZendeskManager.shared.handlePushNotification(payload)
            return true
        }

        return false
    }

    /// This method is only called when the app is in the background
    /// and the user tapped a remote push notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo as NSDictionary
        let isHandled = handleZendeskNotification(userInfo: userInfo)

        if isHandled == false {
            // TODO:
            // =====
            // Refactor both PushNotificationsManager + InteractiveNotificationsManager:
            //
            //  -   InteractiveNotificationsManager should no longer be a singleton. Perhaps we could convert it into a struct.
            //      Plus int should probably be renamed into something more meaningful (and match the new framework's naming)
            //  -   New `NotificationsManager` class:
            //      -   Would inherit `PushNotificationsManager.handleNotification`
            //      -   Would deal with UserNotifications.framework
            //      -   Would use InteractiveNotificationsManager!
            //  -   Nuke `PushNotificationsManager`
            //
            //
            guard let payload = userInfo as? [AnyHashable : Any] else {
                return
            }

            AppDelegate.shared.pushNotesManager.handleNotification(payload) { _ in
                completionHandler()
            }
        }

        completionHandler()
    }
}
