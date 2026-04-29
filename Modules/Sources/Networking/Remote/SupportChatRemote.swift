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
                     context: [String: Any]?) async throws -> SupportChatResponse
}

/// Remote for the support chat endpoint (`/wpcom/v2/odie/chat/{bot_slug}`).
///
public final class SupportChatRemote: Remote, SupportChatRemoteProtocol {

    public func sendMessage(botSlug: String,
                            message: String,
                            chatID: Int64?,
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

        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .post,
                                    path: path,
                                    parameters: parameters,
                                    encoding: JSONEncoding.default)
        let mapper = SupportChatResponseMapper()
        return try await enqueue(request, mapper: mapper)
    }
}

// MARK: - Constants
//
private extension SupportChatRemote {
    enum Path {
        static let chat = "odie/chat"
    }

    enum ParameterKey {
        static let message = "message"
        static let context = "context"
    }
}
