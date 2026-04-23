import Foundation
import Networking

/// Handles `SupportChatAction` by delegating to the `SupportChatRemote`.
///
public final class SupportChatStore: Store {
    private let remote: SupportChatRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = SupportChatRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Allows injecting a mock remote for testing.
    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: SupportChatRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SupportChatAction.self)
    }

    public override func onAction(_ action: Action) {
        guard let action = action as? SupportChatAction else {
            assertionFailure("SupportChatStore received an unsupported action")
            return
        }

        switch action {
        case let .sendMessage(botSlug, message, chatID, context, completion):
            sendMessage(botSlug: botSlug, message: message, chatID: chatID, context: context, completion: completion)
        }
    }
}

// MARK: - Private Methods
//
private extension SupportChatStore {
    func sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     context: [String: Any]?,
                     completion: @escaping (Result<SupportChatResponse, Error>) -> Void) {
        Task {
            let result = await Result {
                try await remote.sendMessage(botSlug: botSlug,
                                             message: message,
                                             chatID: chatID,
                                             context: context)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }
}
