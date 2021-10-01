import XCTest
@testable import WooCommerce
import WooCommerceNotificationServiceExtension
import UserNotifications

final class NotificationServiceTests: XCTestCase {
    private var service: NotificationService!

    override func setUp() {
        super.setUp()
        service = NotificationService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Store order notification - title & body

    func test_order_notification_title_body_is_not_modified_when_pushNotificationsForAllStores_is_disabled() throws {
        // Given
        service.featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: false)
        let content = createOrderNotificationContent()

        // When
        let updatedContent = waitFor { promise in
            self.service.didReceive(UNNotificationRequest(identifier: "", content: content, trigger: nil)) { content in
                promise(content)
            }
        }

        // Then
        XCTAssertEqual(updatedContent.title, content.title)
        XCTAssertEqual(updatedContent.body, content.body)
    }

    func test_order_notification_title_body_is_updated_when_pushNotificationsForAllStores_is_enabled() throws {
        // Given
        service.featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: true)
        let message = Constants.defaultOrderNotificationMessage
        let content = createOrderNotificationContent(messageInPayload: message)

        // When
        let updatedContent = waitFor { promise in
            self.service.didReceive(UNNotificationRequest(identifier: "", content: content, trigger: nil)) { content in
                promise(content)
            }
        }

        // Then
        XCTAssertEqual(updatedContent.title, NSLocalizedString("You have 1 new order! 🎉", comment: "Title of new order push notification."))
        XCTAssertEqual(updatedContent.body, message)
    }

    // MARK: - Store review notification - title & body

    func test_review_notification_title_body_is_updated_when_pushNotificationsForAllStores_is_enabled() throws {
        // Given
        service.featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: true)
        let message = Constants.defaultReviewNotificationMessage
        let content = createReviewNotificationContent(messageInPayload: message)

        // When
        let updatedContent = waitFor { promise in
            self.service.didReceive(UNNotificationRequest(identifier: "", content: content, trigger: nil)) { content in
                promise(content)
            }
        }

        // Then
        XCTAssertEqual(updatedContent.title, Localization.reviewNotificationTitle)
        XCTAssertEqual(updatedContent.body, String.localizedStringWithFormat(Localization.reviewNotificationBodyFormat, content.body, message))
    }

    // MARK: - threadIdentifier

    func test_order_notification_threadIdentifier_includes_notification_type_and_siteID() throws {
        // Given
        service.featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: true)
        let siteID = Int64(256)
        let content = createOrderNotificationContent(siteID: siteID)

        // When
        let updatedContent = waitFor { promise in
            self.service.didReceive(UNNotificationRequest(identifier: "", content: content, trigger: nil)) { content in
                promise(content)
            }
        }

        // Then
        XCTAssertEqual(updatedContent.threadIdentifier, "\(NotificationType.storeOrder.rawValue) \(siteID)")
    }

    func test_review_notification_threadIdentifier_includes_notification_type_and_siteID() throws {
        // Given
        service.featureFlagService = MockFeatureFlagService(isPushNotificationsForAllStoresOn: true)
        let siteID = Int64(256)
        let content = createReviewNotificationContent(siteID: siteID)

        // When
        let updatedContent = waitFor { promise in
            self.service.didReceive(UNNotificationRequest(identifier: "", content: content, trigger: nil)) { content in
                promise(content)
            }
        }

        // Then
        XCTAssertEqual(updatedContent.threadIdentifier, "\(NotificationType.storeReview.rawValue) \(siteID)")
    }
}

private extension NotificationServiceTests {
    func createOrderNotificationContent(messageInPayload: String = Constants.defaultOrderNotificationMessage,
                                        siteID: Int64 = Constants.defaultSiteID) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationType.storeOrder.rawValue
        content.body = Constants.defaultOrderNotificationBody
        content.userInfo = [
            NotificationPayloadKey.siteID: siteID,
            NotificationPayloadKey.message: messageInPayload
        ]
        return content
    }

    func createReviewNotificationContent(messageInPayload: String = Constants.defaultReviewNotificationMessage,
                                        siteID: Int64 = Constants.defaultSiteID) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = NotificationType.storeReview.rawValue
        content.body = Constants.defaultReviewNotificationBody
        content.userInfo = [
            NotificationPayloadKey.siteID: siteID,
            NotificationPayloadKey.message: messageInPayload
        ]
        return content
    }
}

private extension NotificationServiceTests {
    enum Constants {
        static let defaultSiteID = Int64(520)
        static let defaultOrderNotificationMessage = "New order for $47,25 on fun testing"
        static let defaultOrderNotificationBody = "You have a new order! 🎉"
        static let defaultReviewNotificationMessage = "Love the style 🧢"
        static let defaultReviewNotificationBody = "Moo left a review on Cap"
    }

    enum NotificationPayloadKey {
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
