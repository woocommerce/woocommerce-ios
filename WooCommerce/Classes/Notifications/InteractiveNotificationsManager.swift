import Foundation
import UserNotifications


class InteractiveNotificationsManager: NSObject {

}

extension InteractiveNotificationsManager: UNUserNotificationCenterDelegate {
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
            type == ZendeskManager.PushNotificationIdentifiers.type {
            ZendeskManager.shared.handlePushNotification(userInfo)
        }
    }
}
