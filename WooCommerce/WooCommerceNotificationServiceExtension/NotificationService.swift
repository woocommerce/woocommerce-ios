import UserNotifications
import NotificationServiceExtension

/// A UNNotificationServiceExtension subclass must be defined in the extension target and is set in Info.plist's `NSExtensionPrincipalClass` field.
/// The main logic is in `NotificationServiceExtension.NotificationService`, which is in a separate framework for unit testing.
final class NotificationService: UNNotificationServiceExtension {
    private let service: UNNotificationServiceExtension = NotificationServiceExtension.NotificationService()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        service.didReceive(request, withContentHandler: contentHandler)
    }

    override func serviceExtensionTimeWillExpire() {
        service.serviceExtensionTimeWillExpire()
    }
}
