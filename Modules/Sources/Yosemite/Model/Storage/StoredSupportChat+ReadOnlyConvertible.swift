import Foundation
import Storage


// MARK: - Storage.StoredSupportChat: ReadOnlyConvertible
//
extension Storage.StoredSupportChat: ReadOnlyConvertible {

    /// Updates the `Storage.StoredSupportChat` from the ReadOnly representation (`Yosemite.SupportChatSummary`).
    ///
    public func update(with summary: Yosemite.SupportChatSummary) {
        chatID = summary.chatID
        siteID = summary.siteID
        wpcomUserID = summary.wpcomUserID
        botSlug = summary.botSlug
        title = summary.title
        createdAt = summary.createdAt
        updatedAt = summary.updatedAt
    }

    /// Returns a ReadOnly (`Yosemite.SupportChatSummary`) version of the `Storage.StoredSupportChat`.
    ///
    public func toReadOnly() -> Yosemite.SupportChatSummary {
        SupportChatSummary(chatID: chatID,
                           siteID: siteID,
                           wpcomUserID: wpcomUserID,
                           botSlug: botSlug ?? "",
                           title: title,
                           createdAt: createdAt ?? Date(),
                           updatedAt: updatedAt ?? Date())
    }
}
