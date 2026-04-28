import Foundation
import Networking
import Storage

struct MockSupportChatActionHandler: MockActionHandler {
    typealias ActionType = SupportChatAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
        case let .sendMessage(_, _, _, _, completion):
            completion(.success(Self.emptyResponse))
        case let .fetchChat(_, _, completion):
            completion(.success(Self.emptyResponse))
        case let .registerChat(_, _, _, _, _, onCompletion):
            onCompletion(nil)
        case let .touchChat(_, onCompletion):
            onCompletion(nil)
        case let .loadChatHistory(_, onCompletion):
            onCompletion(.success([]))
        case let .deleteChat(_, onCompletion):
            onCompletion(nil)
        }
    }

    private static let emptyResponse = SupportChatResponse(
        chatID: 0,
        sessionID: "",
        botSlug: "",
        botVersion: "",
        messages: []
    )
}
