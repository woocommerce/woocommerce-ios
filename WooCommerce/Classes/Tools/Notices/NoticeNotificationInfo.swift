import Foundation


/// Represents a Notice, for UNNotificationCenter Usage
///
struct NoticeNotificationInfo {

    /// Unique identifier for this notice. When displayed as a system notification, this value will be used as the
    /// `UNNotificationRequest`'s identifier.
    ///
    let identifier: String

    /// Optional category identifier for this notice. If provided, this value will be used as the `UNNotificationContent`'s
    /// category identifier.
    ///
    let categoryIdentifier: String?

    /// Optional title. If provided, this will override the notice's standard title when displayed as a notification.
    ///
    let title: String?

    /// Optional body text. If provided, this will override the notice's standard message when displayed as a notification.
    ///
    let body: String?

    /// If provided, this will be added to the `UNNotificationRequest` for this notice.
    ///
    let userInfo: [String: Any]?


    /// Designated Initializer
    ///
    init(identifier: String, categoryIdentifier: String? = nil, title: String? = nil, body: String? = nil, userInfo: [String: Any]? = nil) {
        self.identifier = identifier
        self.categoryIdentifier = categoryIdentifier
        self.title = title
        self.body = body
        self.userInfo = userInfo
    }
}
