import Foundation

/// A lightweight bookmark for a support chat conversation, used by the chat history UI.
///
/// Persisted locally in Core Data so the merchant can revisit a previous conversation,
/// share its `chatID` with human support, or continue it by reusing the `chatID` on a new
/// message. Message bodies are not stored locally — the assistant holds the canonical thread.
///
public struct SupportChatSummary: Equatable {
    public let chatID: Int64
    public let siteID: Int64
    public let wpcomUserID: Int64
    public let botSlug: String
    public let title: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(chatID: Int64,
                siteID: Int64,
                wpcomUserID: Int64,
                botSlug: String,
                title: String?,
                createdAt: Date,
                updatedAt: Date) {
        self.chatID = chatID
        self.siteID = siteID
        self.wpcomUserID = wpcomUserID
        self.botSlug = botSlug
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
