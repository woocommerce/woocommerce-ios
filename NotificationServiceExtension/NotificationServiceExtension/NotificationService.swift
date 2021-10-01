import Experiments
import UserNotifications

/// Modifies notification content based on payload from the server to support push notifications for all stores.
/// It groups push notifications by site ID and notification type (`threadIdentifier`), and updates a notification's `title` and `body` if the message field is available in the payload.
public class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNNotificationContent?

    // `UNNotificationServiceExtension` does not allow a custom initializer, thus the feature flag service is a public property for unit testing.
    private let featureFlagService: FeatureFlagService

    public init(featureFlagService: FeatureFlagService = DefaultFeatureFlagService()) {
        self.featureFlagService = featureFlagService
    }

    public override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }

        guard featureFlagService.isFeatureFlagEnabled(.pushNotificationsForAllStores) else {
            setContent(content)
            return
        }

        guard let type = NotificationType(rawValue: content.categoryIdentifier),
              let siteID = content.userInfo[NotificationKey.siteID] as? Int64 else {
            setContent(content)
            return
        }

        content.threadIdentifier = "\(type.rawValue) \(siteID)"

        switch type {
        case .storeOrder:
            if let message = content.userInfo[NotificationKey.message] as? String {
                content.title = Localization.orderNotificationTitle
                content.body = message
            }
        case .storeReview:
            if let message = content.userInfo[NotificationKey.message] as? String {
                content.title = Localization.reviewNotificationTitle
                let prompt = content.body
                content.body = String.localizedStringWithFormat(Localization.reviewNotificationBodyFormat, prompt, message)
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
private extension NotificationService {
    enum NotificationKey {
        static let siteID = "blog"
        static let message = "message"
    }

    enum NotificationType: String {
        case storeOrder = "store_order"
        case storeReview = "store_review"
    }

    enum Localization {
        static let orderNotificationTitle = NSLocalizedString("You have 1 new order! 🎉", comment: "Title of new order push notification.")
        static let reviewNotificationTitle = NSLocalizedString("You have 1 new review! ⭐️", comment: "Title of new review push notification.")
        static let reviewNotificationBodyFormat = NSLocalizedString("%1$@: %2$@", comment: "Body format of new review push notification."
                                                                        + " %1$@ reads like 'User name left a review on product name."
                                                                        + " %2$@ is the review content.")
    }
}
