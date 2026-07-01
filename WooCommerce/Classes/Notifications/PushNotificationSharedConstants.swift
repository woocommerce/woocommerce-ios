import Foundation

/// Constants shared between the main WooCommerce app and the NotificationServiceExtension.
enum PushNotificationSharedConstants {
    static let appGroupID = "group.com.automattic.woocommerce"

    /// Push notification `type` values this app version knows how to handle. New types must be
    /// added here as they are introduced — pushes with any other `type` are silently discarded
    /// so newer server-side push types do not surface broken UI in older clients.
    ///
    /// Mirrors `NetworkingCore.Note.Kind` raw values (minus `.unknown`) plus the two non-Kind
    /// app-level types (`badge-reset`, `zendesk`). Centralised here because the
    /// NotificationServiceExtension target cannot import `NetworkingCore`. See RSM-3048.
    static let knownPushNotificationTypes: Set<String> = [
        // Note.Kind raw values (excluding `.unknown`)
        "automattcher",
        "comment",
        "comment_like",
        "follow",
        "like",
        "new_post",
        "post",
        "store_order",
        "store_stock",
        "user",
        "blaze_performed_note",
        "blaze_cancelled_note",
        "blaze_rejected_note",
        "blaze_approved_note",
        // App-level non-Kind types
        "badge-reset",
        "zendesk"
    ]

    /// Returns `true` when the payload's `type` field is missing (e.g. local notification)
    /// or its value is in the known set. Unknown remote types should be silently discarded.
    static func isKnownNotificationType(in userInfo: [AnyHashable: Any]) -> Bool {
        guard let type = userInfo["type"] as? String else {
            return true
        }
        return knownPushNotificationTypes.contains(type)
    }

    /// Push notification `type` values delivered by the Woo-driven (self-driven) push system.
    /// Used to suppress lingering Woo-driven pushes once the app has fallen back to WPCom.
    ///
    /// - Note: scoped to the unambiguous Woo-only types. Woo-driven *reviews* arrive as
    ///   `type: comment` (with no `note_id`) and are intentionally not covered here to avoid any
    ///   risk of touching WPCom comment pushes.
    static let wooDrivenPushTypes: Set<String> = [
        "store_order",
        "store_stock"
    ]

    enum UserDefaultsKeys {
        static let deviceToken = "deviceToken"
        static let deviceID = "deviceID"
        static let wooPushNotificationToken = "wooPushNotificationToken"
        static let siteIDsRegisteredForWooPushNotifications = "siteIDsRegisteredForWooPushNotifications"
        static let selfDrivenPushEnabled = "selfDrivenPushEnabled"
    }
}
