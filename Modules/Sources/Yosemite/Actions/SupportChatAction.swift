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

    /// Persists a new chat bookmark so the merchant can revisit it later.
    ///
    /// Called once per chat, typically after the first successful `sendMessage` response.
    /// No-op if a row with `chatID` already exists.
    ///
    /// - Parameters:
    ///   - chatID: Identifier returned by the assistant.
    ///   - siteID: Primary scoping key. Must be non-zero for post-login chats.
    ///   - wpcomUserID: Secondary identifier. Pass `0` for non-WPCom-authenticated users.
    ///   - botSlug: Assistant slug backing the chat.
    ///   - firstUserMessage: Used to derive the chat's title. Trimmed and clamped to 50 chars.
    ///   - onCompletion: Delivered on the main thread. `nil` on success.
    case registerChat(chatID: Int64,
                      siteID: Int64,
                      wpcomUserID: Int64,
                      botSlug: String,
                      firstUserMessage: String,
                      onCompletion: (Error?) -> Void)

    /// Bumps the `updatedAt` timestamp for an existing chat so it surfaces at the top of history.
    ///
    /// Idempotent: if no row exists for `chatID`, completes without error.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to bump.
    ///   - onCompletion: Delivered on the main thread. `nil` on success.
    case touchChat(chatID: Int64,
                   onCompletion: (Error?) -> Void)

    /// Loads all locally-persisted chat bookmarks for a site, sorted newest first.
    ///
    /// - Parameters:
    ///   - siteID: Scoping key.
    ///   - onCompletion: Delivered on the main thread with the list of summaries.
    case loadChatHistory(siteID: Int64,
                         onCompletion: (Result<[SupportChatSummary], Error>) -> Void)

    /// Deletes a single chat bookmark from local storage.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to delete.
    ///   - onCompletion: Delivered on the main thread. `nil` on success.
    case deleteChat(chatID: Int64,
                    onCompletion: (Error?) -> Void)
}
