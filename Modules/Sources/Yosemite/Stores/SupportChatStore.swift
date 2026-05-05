import Foundation
import Networking
import Storage

/// Handles `SupportChatAction` by delegating to the `SupportChatRemote` (network) and the
/// `StorageManager` (local chat history).
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
        case let .sendMessage(botSlug, message, chatID, sessionID, context, completion):
            sendMessage(botSlug: botSlug, message: message, chatID: chatID, sessionID: sessionID, context: context, completion: completion)
        case let .fetchChat(botSlug, chatID, completion):
            fetchChat(botSlug: botSlug, chatID: chatID, completion: completion)
        case let .registerChat(chatID, siteID, wpcomUserID, botSlug, firstUserMessage, onCompletion):
            registerChat(chatID: chatID,
                         siteID: siteID,
                         wpcomUserID: wpcomUserID,
                         botSlug: botSlug,
                         firstUserMessage: firstUserMessage,
                         onCompletion: onCompletion)
        case let .touchChat(chatID, onCompletion):
            touchChat(chatID: chatID, onCompletion: onCompletion)
        case let .loadChatHistory(siteID, onCompletion):
            loadChatHistory(siteID: siteID, onCompletion: onCompletion)
        case let .deleteChat(chatID, onCompletion):
            deleteChat(chatID: chatID, onCompletion: onCompletion)
        }
    }
}

// MARK: - Network
//
private extension SupportChatStore {
    func sendMessage(botSlug: String,
                     message: String,
                     chatID: Int64?,
                     sessionID: String?,
                     context: [String: Any]?,
                     completion: @escaping (Result<SupportChatResponse, Error>) -> Void) {
        Task {
            let result = await Result {
                try await remote.sendMessage(botSlug: botSlug,
                                             message: message,
                                             chatID: chatID,
                                             sessionID: sessionID,
                                             context: context)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }

    func fetchChat(botSlug: String,
                   chatID: Int64,
                   completion: @escaping (Result<SupportChatResponse, Error>) -> Void) {
        Task {
            let result = await Result {
                try await remote.fetchChat(botSlug: botSlug, chatID: chatID)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }
}

// MARK: - Local history
//
private extension SupportChatStore {

    func registerChat(chatID: Int64,
                      siteID: Int64,
                      wpcomUserID: Int64,
                      botSlug: String,
                      firstUserMessage: String,
                      onCompletion: @escaping () -> Void) {
        let title = Self.deriveTitle(from: firstUserMessage)
        let now = Date()

        storageManager.performAndSave({ storage in
            // No-op if a row already exists for this chatID (duplicate dispatch or retry).
            guard storage.loadSupportChat(chatID: chatID) == nil else {
                return
            }
            let chat = storage.insertNewObject(ofType: StoredSupportChat.self)
            chat.chatID = chatID
            chat.siteID = siteID
            chat.wpcomUserID = wpcomUserID
            chat.botSlug = botSlug
            chat.title = title
            chat.createdAt = now
            chat.updatedAt = now
        }, completion: {
            onCompletion()
        }, on: .main)
    }

    func touchChat(chatID: Int64, onCompletion: @escaping () -> Void) {
        let now = Date()
        storageManager.performAndSave({ storage in
            guard let chat = storage.loadSupportChat(chatID: chatID) else {
                // Idempotent — row may have been deleted between turns.
                return
            }
            chat.updatedAt = now
        }, completion: {
            onCompletion()
        }, on: .main)
    }

    func loadChatHistory(siteID: Int64,
                         onCompletion: @escaping ([SupportChatSummary]) -> Void) {
        let summaries = storageManager.viewStorage
            .loadSupportChats(siteID: siteID)
            .map { $0.toReadOnly() }
        onCompletion(summaries)
    }

    func deleteChat(chatID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteSupportChat(chatID: chatID)
        }, completion: {
            onCompletion()
        }, on: .main)
    }
}

// MARK: - Helpers
//
private extension SupportChatStore {
    /// Trims whitespace and clamps `message` to 50 characters, preserving Unicode scalars.
    /// Returns `nil` if the resulting string is empty.
    static func deriveTitle(from message: String) -> String? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxLength = 50
        if trimmed.count <= maxLength {
            return trimmed
        }
        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<endIndex])
    }
}
