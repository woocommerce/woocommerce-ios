import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        if shouldSuppressNotifications(with: request.content.userInfo) {
            let remover = DeliveredNotificationRemover(identifier: request.identifier)
            contentHandler(UNMutableNotificationContent())
            // The remover's asynchronous callback chain retains it until removal completes or times out.
            remover.start()
            return
        }
        contentHandler(request.content)
    }
}

private extension NotificationService {
    func shouldSuppressNotifications(with userInfo: [AnyHashable: Any]) -> Bool {
        guard PushNotificationSharedConstants.isKnownNotificationType(in: userInfo) else {
            let type = (userInfo["type"] as? String) ?? "<missing>"
            NSLog("📱 NSE: discarded push with unknown type \(type)")
            return true
        }

        guard let defaults = UserDefaults(suiteName: PushNotificationSharedConstants.appGroupID) else {
            return false
        }

        let registrationState = PushNotificationRegistrationState(defaults: defaults)
        return registrationState.shouldSuppressNotification(userInfo: userInfo)
    }
}

/// Removes a suppressed notification after iOS adds it to Notification Center.
///
/// Returning from the notification content handler does not mean that delivery has completed.
/// Removing the notification immediately can therefore be ignored because its identifier is not
/// in Notification Center yet. Polling briefly lets removal begin only after delivery is visible.
// Mutable state is confined to `queue`.
private final class DeliveredNotificationRemover: @unchecked Sendable {
    private static let timeout: TimeInterval = 1
    private static let retryDelay: DispatchTimeInterval = .milliseconds(20)

    private let identifier: String
    private let notificationCenter: UNUserNotificationCenter
    private let queue = DispatchQueue(label: "com.woocommerce.delivered-notification-remover")
    private let deadline: DispatchTime
    private var removalRequested = false

    init(identifier: String, notificationCenter: UNUserNotificationCenter = .current()) {
        self.identifier = identifier
        self.notificationCenter = notificationCenter
        deadline = .now() + Self.timeout
    }

    func start() {
        queue.async {
            self.checkDeliveryState()
        }
    }

    private func checkDeliveryState() {
        notificationCenter.getDeliveredNotifications { notifications in
            let deliveredIdentifiers = Set(notifications.map(\.request.identifier))
            self.queue.async {
                self.handleDeliveryState(deliveredIdentifiers)
            }
        }
    }

    private func handleDeliveryState(_ deliveredIdentifiers: Set<String>) {
        let isDelivered = deliveredIdentifiers.contains(identifier)
        if isDelivered && removalRequested == false {
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
            removalRequested = true
        } else if isDelivered == false && removalRequested {
            return
        }

        guard DispatchTime.now() < deadline else {
            NSLog("📱 NSE: timed out while removing a suppressed notification")
            return
        }

        queue.asyncAfter(deadline: .now() + Self.retryDelay) {
            self.checkDeliveryState()
        }
    }
}
