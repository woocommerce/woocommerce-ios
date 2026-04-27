import Foundation
import Observation
import Yosemite
import protocol WooFoundation.Analytics
import enum Networking.NetworkError

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
    private let onContactHumanSupport: () -> Void
    private let analytics: Analytics
    private let entryPoint: WooAnalyticsEvent.SupportChat.EntryPoint
    private let authState: WooAnalyticsEvent.SupportChat.AuthState
    private var openedTracked = false
    private var closedTracked = false

    // MARK: - Initialization

    init(botSlug: String = "woo-workflow-support_mobile_inapp",
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         entryPoint: WooAnalyticsEvent.SupportChat.EntryPoint = .connectivityTool,
         authState: WooAnalyticsEvent.SupportChat.AuthState = .wpcom,
         initialContext: [String: Any]? = nil,
         chatID: Int64? = nil,
         onContactHumanSupport: @escaping () -> Void) {
        self.botSlug = botSlug
        self.stores = stores
        self.analytics = analytics
        self.entryPoint = entryPoint
        self.authState = authState
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
            let greetingMessage = ChatMessage(role: .assistant, content: Localization.greetingMessage)
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

        analytics.track(event: .SupportChat.messageSent(chatID: chatID,
                                                        entryPoint: entryPoint))

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
        analytics.track(event: .SupportChat.contactHumanTapped(chatID: chatID))
        onContactHumanSupport()
    }

    /// Fires `support_chat_opened` exactly once per view lifetime.
    /// Idempotent so repeat `.onAppear` calls (e.g. nav back-forward) don't double-track.
    func trackOpenedIfNeeded() {
        guard !openedTracked else { return }
        openedTracked = true
        analytics.track(event: .SupportChat.opened(entryPoint: entryPoint,
                                                   authState: authState,
                                                   chatResumed: isResumedChat))
    }

    /// Fires `support_chat_closed` exactly once per view lifetime, with funnel-friendly properties.
    /// Resolution is derived from current state at close time.
    func trackClosedIfNeeded() {
        guard !closedTracked else { return }
        closedTracked = true
        let resolution: WooAnalyticsEvent.SupportChat.Resolution = {
            if shouldPromptHumanSupport {
                return .escalated
            }
            if chatID == nil {
                return .dismissedNoMessageSent
            }
            return .completed
        }()
        analytics.track(event: .SupportChat.closed(chatID: chatID,
                                                   resolution: resolution,
                                                   messageCount: messages.count))
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

                let flags = lastBotMessage.context?.flags
                let sourcesCount = lastBotMessage.context?.sources.count ?? 0
                analytics.track(event: .SupportChat.messageReceived(chatID: response.chatID,
                                                                    botVersion: response.botVersion,
                                                                    branch: flags?.branch,
                                                                    cannedResponse: flags?.cannedResponse ?? false,
                                                                    sourcesCount: sourcesCount))

                if let flags, flags.forwardToHumanSupport {
                    shouldPromptHumanSupport = true
                    analytics.track(event: .SupportChat.forwardToHumanTriggered(chatID: response.chatID,
                                                                                messageID: lastBotMessage.messageID,
                                                                                branch: flags.branch))
                }
            }

            state = .idle

        case .failure(let error):
            DDLogError("⛔️ Support chat error: \(error)")
            analytics.track(event: .SupportChat.messageFailed(errorClass: classify(error: error),
                                                              httpStatus: httpStatus(for: error),
                                                              chatID: chatID))
            state = .error(Localization.errorMessage)
        }
    }

    /// Buckets a generic `Error` into a coarse class for analytics. Avoids leaking server text.
    private func classify(error: Error) -> WooAnalyticsEvent.SupportChat.ErrorClass {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout:
                return .timeout
            case let .unacceptableStatusCode(statusCode, _):
                if statusCode == 401 || statusCode == 403 {
                    return .unauthorized
                }
                if statusCode == 429 {
                    return .rateLimit
                }
                return .server
            case .notFound:
                return .server
            case .invalidURL, .invalidCookieNonce:
                return .network
            }
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorUserAuthenticationRequired:
                return .unauthorized
            default:
                return .network
            }
        }
        if error is DecodingError {
            return .decoding
        }
        return .unknown
    }

    /// Best-effort HTTP status extraction. Returns nil when the error doesn't carry one.
    private func httpStatus(for error: Error) -> Int? {
        guard let networkError = error as? NetworkError else { return nil }
        return networkError.responseCode
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
                    return ChatMessage(role: .assistant, content: message.content)
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
        static let resumeErrorMessage = NSLocalizedString(
            "supportChatViewModel.resumeErrorMessage",
            value: "We couldn't load the previous conversation. You can still send a new message.",
            comment: "Error message shown when loading a prior support chat transcript fails on resume"
        )
    }
}
