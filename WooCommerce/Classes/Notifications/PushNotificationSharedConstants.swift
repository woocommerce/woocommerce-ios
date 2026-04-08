import Foundation

/// Constants shared between the main WooCommerce app and the NotificationServiceExtension.
enum PushNotificationSharedConstants {
    static let appGroupID = "group.com.automattic.woocommerce"

    enum UserDefaultsKeys {
        static let deviceToken = "deviceToken"
        static let deviceID = "deviceID"
        static let wooPushNotificationToken = "wooPushNotificationToken"
        static let siteIDsRegisteredForWooPushNotifications = "siteIDsRegisteredForWooPushNotifications"
    }
}
