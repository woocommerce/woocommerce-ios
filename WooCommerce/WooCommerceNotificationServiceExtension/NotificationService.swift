import UserNotifications
import NotificationServiceExtension

final class NotificationService: UNNotificationServiceExtension {
    private lazy var service: UNNotificationServiceExtension = NotificationServiceExtension.NotificationService()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        service.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        service.serviceExtensionTimeWillExpire()
    }
}
