import Experiments
import UserNotifications

public class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNNotificationContent?

    // `UNNotificationServiceExtension` does not allow a custom initializer, thus the feature flag service is a public property for unit testing.
    var featureFlagService: FeatureFlagService = DefaultFeatureFlagService()

    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }

        guard featureFlagService.isFeatureFlagEnabled(.pushNotificationsForAllStores) else {
            setContent(content)
            return
        }

        guard let type = NotificationType(rawValue: content.categoryIdentifier) else {
            setContent(content)
            return
        }

        if let siteID = content.userInfo[NotificationKey.siteID] as? Int {
            content.threadIdentifier = "\(type.rawValue) \(siteID)"
        }

        switch type {
        case .storeOrder:
            if let message = content.userInfo[NotificationKey.message] as? String {
                content.title = NSLocalizedString("You have 1 new order! 🎉", comment: "Title of new order push notification.")
                content.body = message
            }
        case .storeReview:
            if let message = content.userInfo[NotificationKey.message] as? String {
                content.title = NSLocalizedString("You have 1 new review! ⭐️", comment: "Title of new order push notification.")
                let prompt = content.body
                content.body = "\(prompt): \(message)" // TODO: localize
            }
        }

        setContent(content)
    }

    public override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

private extension NotificationService {
    func setContent(_ content: UNNotificationContent) {
        bestAttemptContent = content
        contentHandler?(content)
    }
}

// MARK: - Private Types
//
private enum NotificationKey {
    static let siteID = "blog"
    static let message = "message"
}

private enum NotificationType: String {
    case storeOrder = "store_order"
    case storeReview = "store_review"
}
