import Foundation
@testable import Networking

/// Mock for `SupportChatRemoteProtocol`.
///
final class MockSupportChatRemote: SupportChatRemoteProtocol {
    private var sendMessageResult: Result<SupportChatResponse, Error>?
    private var fetchChatResult: Result<SupportChatResponse, Error>?

    private(set) var sendMessageInvocations: [(botSlug: String, message: String, chatID: Int64?)] = []
    private(set) var fetchChatInvocations: [(botSlug: String, chatID: Int64)] = []

    func whenSendingMessage(thenReturn result: Result<SupportChatResponse, Error>) {
        sendMessageResult = result
    }

    func whenFetchingChat(thenReturn result: Result<SupportChatResponse, Error>) {
        fetchChatResult = result
    }

    func sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     context: [String: Any]?) async throws -> SupportChatResponse {
        sendMessageInvocations.append((botSlug, message, chatID))
        guard let result = sendMessageResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }

    func fetchChat(botSlug: String, chatID: Int64) async throws -> SupportChatResponse {
        fetchChatInvocations.append((botSlug, chatID))
        guard let result = fetchChatResult else {
            throw NetworkError.timeout()
        }
        return try result.get()
    }
}
