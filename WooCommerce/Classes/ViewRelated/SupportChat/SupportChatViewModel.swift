import Foundation
import Observation
import Yosemite
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
        let role: Role
        let content: String
        let timestamp: Date

        enum Role {
            case user
            case assistant
        }

        init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
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

    var inputText: String = ""

    // MARK: - Private Properties

    private var chatID: Int64?
    private let botSlug: String
    private let stores: StoresManager
    private let initialContext: [String: Any]?
    private let onContactHumanSupport: () -> Void

    // MARK: - Initialization

    init(botSlug: String = "woo-workflow-support_woomobile",
         stores: StoresManager = ServiceLocator.stores,
         initialContext: [String: Any]? = nil,
         chatID: Int64? = nil,
         onContactHumanSupport: @escaping () -> Void) {
        self.botSlug = botSlug
        self.stores = stores
        self.initialContext = initialContext
        self.chatID = chatID
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
            let greetingMessage = ChatMessage(role: .assistant, content: Localization.greetingMessage)
            messages.append(greetingMessage)
            state = .idle
        }
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
        onContactHumanSupport()
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
                    role: .assistant,
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
                                                       onCompletion: { _ in })
            stores.dispatch(action)
        } else {
            let action = SupportChatAction.touchChat(chatID: response.chatID,
                                                    onCompletion: { _ in })
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
    }
}
