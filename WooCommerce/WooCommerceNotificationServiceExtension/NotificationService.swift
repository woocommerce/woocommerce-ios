import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }

        guard let type = NotificationType(rawValue: content.categoryIdentifier) else {
            bestAttemptContent = content
            contentHandler(content)
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

        bestAttemptContent = content
        contentHandler(content)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
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
