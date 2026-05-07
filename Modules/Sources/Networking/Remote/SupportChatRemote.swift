import Alamofire
import Foundation

/// Protocol for `SupportChatRemote` — mockable for tests.
///
public protocol SupportChatRemoteProtocol {
    /// Sends a message to the support chat assistant.
    ///
    /// - Parameters:
    ///   - botSlug: Assistant slug (e.g. `woo-chat-allusers`).
    ///   - message: The user's message text.
    ///   - chatID: If provided, continues an existing chat; otherwise starts a new one.
    ///   - context: Optional context object forwarded to the assistant (e.g. selected site, current screen).
    /// - Returns: The full chat thread with the assistant's reply appended.
    func sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     sessionID: String?,
                     context: [String: Any]?) async throws -> SupportChatResponse

    /// Fetches an existing chat thread by id, returning every turn (user + bot).
    ///
    /// - Parameters:
    ///   - botSlug: Assistant slug the chat was created against.
    ///   - chatID: Identifier returned by a previous `sendMessage` call.
    /// - Returns: The full thread in `ts`-ascending order.
    func fetchChat(botSlug: String,
                   chatID: Int64) async throws -> SupportChatResponse

    /// Submits feedback for a specific bot message.
    ///
    /// - Parameters:
    ///   - messageID: Identifier of the message to rate.
    ///   - sessionID: Session identifier of the chat.
    ///   - upvoted: `true` for positive feedback (thumbs up), `false` for negative (thumbs down).
    func submitFeedback(messageID: Int64,
                        sessionID: String,
                        upvoted: Bool) async throws
}

/// Remote for the support chat endpoint (`/wpcom/v2/odie/chat/{bot_slug}`).
///
public final class SupportChatRemote: Remote, SupportChatRemoteProtocol {

    public func sendMessage(botSlug: String,
                            message: String,
                            chatID: Int64?,
                            sessionID: String?,
                            context: [String: Any]?) async throws -> SupportChatResponse {
        let path: String = {
            if let chatID {
                return "\(Path.chat)/\(botSlug)/\(chatID)"
            }
            return "\(Path.chat)/\(botSlug)"
        }()

        var parameters: [String: Any] = [ParameterKey.message: message]
        if let context {
            parameters[ParameterKey.context] = context
        }
        if let sessionID {
            parameters[ParameterKey.sessionID] = sessionID
        }

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path,
                                    parameters: parameters,
                                    encoding: JSONEncoding.default)
        let mapper = SupportChatResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func fetchChat(botSlug: String,
                          chatID: Int64) async throws -> SupportChatResponse {
        let path = "\(Path.chat)/\(botSlug)/\(chatID)"
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: path)
        let mapper = SupportChatResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }

    public func submitFeedback(messageID: Int64,
                               sessionID: String,
                               upvoted: Bool) async throws {
        let path = "\(Path.feedback)/\(sessionID)/rate"
        let parameters: [String: Any] = [
            ParameterKey.messageID: messageID,
            ParameterKey.rating: upvoted ? "up" : "down"
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path,
                                    parameters: parameters,
                                    encoding: JSONEncoding.default)
        _ = try await enqueue(request)
    }
}

// MARK: - Constants
//
private extension SupportChatRemote {
    enum Path {
        static let chat = "odie/chat"
        static let feedback = "ai/feedback"
    }

    enum ParameterKey {
        static let message = "message"
        static let context = "context"
        static let sessionID = "session_id"
        static let messageID = "message_id"
        static let rating = "rating"
    }
}
