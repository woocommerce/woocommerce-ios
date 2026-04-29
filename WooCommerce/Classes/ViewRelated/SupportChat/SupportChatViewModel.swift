import Foundation
import Observation
import Yosemite
import enum Networking.SupportChatRole
import protocol WooFoundation.Analytics

/// View model for the AI support chat interface.
///
@MainActor
@Observable
final class SupportChatViewModel {

    /// Represents the current state of the chat.
    ///
    enum State: Equatable {
        case idle
        case sending
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.sending, .sending):
                return true
            case let (.error(lhsMessage), .error(rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }

    /// A message in the chat thread (local UI model).
    ///
    struct ChatMessage: Identifiable, Equatable {
        let id: UUID
        let role: SupportChatRole
        let content: String
        let timestamp: Date

        init(id: UUID = UUID(), role: SupportChatRole, content: String, timestamp: Date = Date()) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }
    }

    // MARK: - Published State

    private(set) var messages: [ChatMessage] = []
    private(set) var state: State = .idle
    private(set) var shouldPromptHumanSupport: Bool = false

    /// `true` when the view model was seeded with a prior `chatID` — i.e. the merchant
    /// tapped a history row rather than starting fresh. Drives the "Continuing conversation"
    /// header in the chat surface.
    let isResumedChat: Bool

    var inputText: String = ""

    // MARK: - Private Properties

    private var chatID: Int64?
    private let botSlug: String
    private let stores: StoresManager
    private let initialContext: [String: Any]?
    private let onContactHumanSupport: (_ transcript: String) -> Void

    // MARK: - Initialization

    init(botSlug: String = "woo-workflow-support_mobile_inapp",
         stores: StoresManager = ServiceLocator.stores,
         initialContext: [String: Any]? = nil,
         chatID: Int64? = nil,
         onContactHumanSupport: @escaping (_ transcript: String) -> Void) {
        self.botSlug = botSlug
        self.stores = stores
        self.initialContext = initialContext
        self.chatID = chatID
        self.isResumedChat = chatID != nil
        self.onContactHumanSupport = onContactHumanSupport
    }

    // MARK: - Actions

    func showGreeting() {
        guard messages.isEmpty else { return }
        // Resumed chats skip the greeting — the merchant is continuing a prior conversation.
        guard chatID == nil else { return }
        state = .sending

        Task {
            try? await Task.sleep(for: .seconds(1))
            let greetingMessage = ChatMessage(role: .bot, content: Localization.greetingMessage)
            messages.append(greetingMessage)
            state = .idle
        }
    }

    /// Fetches the prior transcript for a resumed chat and populates `messages`.
    /// No-op for fresh chats or if messages have already been loaded.
    func resumeIfNeeded() {
        guard let chatID else { return }
        guard messages.isEmpty else { return }
        state = .sending

        let action = SupportChatAction.fetchChat(botSlug: botSlug, chatID: chatID) { [weak self] result in
            self?.handleFetchChatResult(result)
        }
        stores.dispatch(action)
    }

    func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        guard state != .sending else { return }

        let userMessage = ChatMessage(role: .user, content: trimmedText)
        messages.append(userMessage)
        inputText = ""
        state = .sending

        let context = chatID == nil ? initialContext : nil
        let wasNewChat = chatID == nil
        let firstUserMessage = trimmedText

        let action = SupportChatAction.sendMessage(
            botSlug: botSlug,
            message: trimmedText,
            chatID: chatID,
            context: context
        ) { [weak self] result in
            self?.handleSendMessageResult(result,
                                          wasNewChat: wasNewChat,
                                          firstUserMessage: firstUserMessage)
        }

        stores.dispatch(action)
    }

    func contactHumanSupport() {
        onContactHumanSupport(generateTranscript())
    }

    private func generateTranscript() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        return messages.map { message in
            let roleName: String
            switch message.role {
            case .user: roleName = "User"
            case .bot: roleName = "Bot"
            case .unknown: roleName = "Unknown"
            }
            let timestamp = dateFormatter.string(from: message.timestamp)
            return "[\(timestamp)] \(roleName): \(message.content)"
        }.joined(separator: "\n\n")
    }

    func dismissError() {
        state = .idle
    }

    // MARK: - Private Methods

    private func handleSendMessageResult(_ result: Result<SupportChatResponse, Error>,
                                         wasNewChat: Bool,
                                         firstUserMessage: String) {
        switch result {
        case .success(let response):
            chatID = response.chatID
            persistChatBookmark(wasNewChat: wasNewChat,
                                response: response,
                                firstUserMessage: firstUserMessage)

            if let lastBotMessage = response.messages.last(where: { $0.role == .bot }) {
                let assistantMessage = ChatMessage(
                    role: .bot,
                    content: lastBotMessage.content
                )
                messages.append(assistantMessage)

                if let flags = lastBotMessage.context?.flags, flags.forwardToHumanSupport {
                    shouldPromptHumanSupport = true
                }
            }

            state = .idle

        case .failure(let error):
            DDLogError("⛔️ Support chat error: \(error)")
            state = .error(Localization.errorMessage)
        }
    }

    /// Maps a fetched transcript into local `ChatMessage` values. Unknown roles are dropped
    /// rather than rendered as garbage; ordering from the server (ts-ascending) is preserved.
    private func handleFetchChatResult(_ result: Result<SupportChatResponse, Error>) {
        switch result {
        case .success(let response):
            let rehydrated: [ChatMessage] = response.messages.compactMap { message in
                switch message.role {
                case .user:
                    return ChatMessage(role: .user, content: message.content)
                case .bot:
                    return ChatMessage(role: .bot, content: message.content)
                case .unknown:
                    return nil
                }
            }
            messages = rehydrated
            state = .idle

        case .failure(let error):
            DDLogError("⛔️ Support chat resume error: \(error)")
            // Fail soft: the merchant can still send a new message into the existing chatID;
            // they just won't see the prior transcript. Surface as a retry-able error.
            state = .error(Localization.resumeErrorMessage)
        }
    }

    /// Persists a local bookmark for the chat so it appears in the chat history UI.
    /// Fire-and-forget: we don't surface storage errors to the user.
    private func persistChatBookmark(wasNewChat: Bool,
                                     response: SupportChatResponse,
                                     firstUserMessage: String) {
        if wasNewChat {
            guard let siteID = stores.sessionManager.defaultStoreID else {
                // No site context — skip silently. Pre-login / non-WPCom flows aren't persisted yet.
                return
            }
            let wpcomUserID = stores.sessionManager.defaultAccountID ?? -1
            let action = SupportChatAction.registerChat(chatID: response.chatID,
                                                       siteID: siteID,
                                                       wpcomUserID: wpcomUserID,
                                                       botSlug: botSlug,
                                                       firstUserMessage: firstUserMessage,
                                                       onCompletion: {})
            stores.dispatch(action)
        } else {
            let action = SupportChatAction.touchChat(chatID: response.chatID,
                                                    onCompletion: {})
            stores.dispatch(action)
        }
    }
}

// MARK: - Localization
//
private extension SupportChatViewModel {
    enum Localization {
        static let greetingMessage = NSLocalizedString(
            "supportChatViewModel.greetingMessage",
            value: "Hello! I'm your Woo Mobile Support Bot. Is there anything I can help you with today?",
            comment: "Initial greeting message from the AI support bot"
        )
        static let errorMessage = NSLocalizedString(
            "supportChatViewModel.errorMessage",
            value: "Something went wrong. Please try again.",
            comment: "Error message shown when sending a support chat message fails"
        )
        static let resumeErrorMessage = NSLocalizedString(
            "supportChatViewModel.resumeErrorMessage",
            value: "We couldn't load the previous conversation. You can still send a new message.",
            comment: "Error message shown when loading a prior support chat transcript fails on resume"
        )
    }
}
