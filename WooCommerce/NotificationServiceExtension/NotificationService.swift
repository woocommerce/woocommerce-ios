import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        if shouldSuppressNotifications(with: request.content.userInfo) {
            let silentContent = UNMutableNotificationContent()
            contentHandler(silentContent)
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: [request.identifier]
            )
            return
        }
        contentHandler(request.content)
    }
}

private extension NotificationService {
    func shouldSuppressNotifications(with userInfo: [AnyHashable: Any]) -> Bool {
        guard let defaults = UserDefaults(suiteName: PushNotificationSharedConstants.appGroupID) else {
            return false
        }

        let registrationState = PushNotificationRegistrationState(defaults: defaults)
        return registrationState.shouldSuppressWPComNotification(userInfo: userInfo)
    }
}
