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
    ///   - sessionID: Current session if continuing an existing chat
    ///   - context: Optional context forwarded to the assistant (site info, troubleshooting data).
    ///   - completion: Called with the full chat thread including the bot's response.
    case sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     sessionID: String?,
                     context: [String: Any]?,
                     completion: (Result<SupportChatResponse, Error>) -> Void)

    /// Fetches the full transcript of an existing chat so the UI can rehydrate a resumed session.
    ///
    /// - Parameters:
    ///   - botSlug: Assistant slug the chat was created against.
    ///   - chatID: Identifier returned by a previous `sendMessage`.
    ///   - sessionID: Optional session identifier required by unauthenticated chats.
    ///   - completion: Called on the main thread with every turn (user + bot) in ascending order.
    case fetchChat(botSlug: String,
                   chatID: Int64,
                   sessionID: String?,
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
    ///   - sessionID: Session identifier returned by the assistant.
    ///   - firstUserMessage: Used to derive the chat's title. Trimmed and clamped to 50 chars.
    ///   - onCompletion: Delivered on the main thread once the row is persisted.
    case registerChat(chatID: Int64,
                      siteID: Int64,
                      wpcomUserID: Int64,
                      botSlug: String,
                      sessionID: String?,
                      firstUserMessage: String,
                      onCompletion: () -> Void)

    /// Bumps the `updatedAt` timestamp for an existing chat so it surfaces at the top of history.
    ///
    /// Idempotent: if no row exists for `chatID`, completes without doing anything.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to bump.
    ///   - sessionID: Optional latest session identifier to persist for resumed unauthenticated fetches.
    ///   - onCompletion: Delivered on the main thread once the bump is persisted.
    case touchChat(chatID: Int64,
                   sessionID: String?,
                   onCompletion: () -> Void)

    /// Loads all locally-persisted chat bookmarks for a site, sorted newest first.
    ///
    /// - Parameters:
    ///   - siteID: Scoping key.
    ///   - onCompletion: Delivered on the main thread with the list of summaries.
    case loadChatHistory(siteID: Int64,
                         onCompletion: ([SupportChatSummary]) -> Void)

    /// Deletes a single chat bookmark from local storage.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to delete.
    ///   - onCompletion: Delivered on the main thread once the row is removed.
    case deleteChat(chatID: Int64,
                    onCompletion: () -> Void)

    /// Marks an existing chat as having created a support ticket.
    ///
    /// Called after a Zendesk support ticket is created for a chat session.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to update.
    ///   - onCompletion: Delivered on the main thread once the update is persisted.
    case markTicketCreated(chatID: Int64,
                           onCompletion: () -> Void)

    /// Marks an existing chat as resolved.
    ///
    /// Called after the merchant confirms the support chat resolved their issue.
    ///
    /// - Parameters:
    ///   - chatID: Identifier of the chat to update.
    ///   - onCompletion: Delivered on the main thread once the update is persisted.
    case markResolved(chatID: Int64,
                      onCompletion: () -> Void)

    /// Submits feedback for a specific bot message.
    ///
    /// - Parameters:
    ///   - botSlug: Assistant slug (e.g. `woo-chat-allusers`).
    ///   - chatID: Identifier of the chat.
    ///   - messageID: Identifier of the message to rate.
    ///   - sessionID: Session identifier of the chat.
    ///   - upvoted: `true` for positive feedback (thumbs up), `false` for negative (thumbs down).
    ///   - onCompletion: Called when the feedback submission completes.
    case submitFeedback(botSlug: String,
                        chatID: Int64,
                        messageID: Int64,
                        sessionID: String,
                        upvoted: Bool,
                        onCompletion: (Result<Void, Error>) -> Void)
}
