import Foundation

/// Defines actions for the AI support chat feature.
///
public enum SupportChatAction: Action {
    /// Sends a message to the support chat bot.
    ///
    /// - Parameters:
    ///   - botSlug: The bot/assistant slug (e.g., "woo-chat-allusers").
    ///   - message: The user's message text.
    ///   - chatID: If provided, continues an existing chat; otherwise starts a new one.
    ///   - context: Optional context forwarded to the assistant (site info, troubleshooting data).
    ///   - completion: Called with the full chat thread including the bot's response.
    case sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     context: [String: Any]?,
                     completion: (Result<SupportChatResponse, Error>) -> Void)
}
