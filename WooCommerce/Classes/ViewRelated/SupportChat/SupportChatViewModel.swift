import Foundation
import Observation
import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// View model for the AI support chat interface.
///
@MainActor
@Observable
final class SupportChatViewModel {

    /// Entry point for opening the support chat.
    ///
    enum EntryPoint {
        case helpAndSupport   // Shows issue picker first
        case connectivityTool // Goes directly to chat (context already provided)
        case chatHistory      // Resuming a prior conversation from history
        case preLogin         // Logged-out surfaces (Help, error screens, prologue, pre-login Connectivity Tool)
    }

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

    /// Progress state for a diagnostic test.
    ///
    enum TestStatus: Equatable {
        case pending
        case running
        case passed
        case failed(String?) // error message
    }

    /// Content types for chat messages.
    ///
    enum MessageContent: Equatable {
        case text(String)
        case issuePicker([SupportIssueType])
        /// Shows step-by-step progress: list of (test, status) pairs
        case diagnosticsProgress([(test: SupportDiagnosticsService.Test, status: TestStatus)])
        /// All tests passed - show simple success message
        case diagnosticsSuccess
        /// A test failed - show failure with optional action
        case diagnosticsFailure(SupportDiagnosticsService.Result)

        static func == (lhs: MessageContent, rhs: MessageContent) -> Bool {
            switch (lhs, rhs) {
            case (.text(let l), .text(let r)):
                return l == r
            case (.issuePicker(let l), .issuePicker(let r)):
                return l == r
            case (.diagnosticsProgress(let l), .diagnosticsProgress(let r)):
                return l.map { $0.test } == r.map { $0.test } &&
                       l.map { $0.status } == r.map { $0.status }
            case (.diagnosticsSuccess, .diagnosticsSuccess):
                return true
            case (.diagnosticsFailure(let l), .diagnosticsFailure(let r)):
                return l == r
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
        let content: MessageContent
        let timestamp: Date

        init(id: UUID = UUID(), role: SupportChatRole, content: MessageContent, timestamp: Date = Date()) {
            self.id = id
            self.role = role
            self.content = content
            self.timestamp = timestamp
        }

        /// Convenience initializer for text messages.
        init(id: UUID = UUID(), role: SupportChatRole, text: String, timestamp: Date = Date()) {
            self.id = id
            self.role = role
            self.content = .text(text)
            self.timestamp = timestamp
        }
    }

    // MARK: - Published State

    private(set) var selectedIssue: SupportIssueType?
    private(set) var diagnosticResults: [SupportDiagnosticsService.Result] = []
    private(set) var messages: [ChatMessage] = []
    private(set) var state: State = .idle
    private(set) var shouldPromptHumanSupport: Bool = false


    /// Whether the input area should be shown.
    /// Hidden during issue picker and diagnostics phases.
    ///
    var shouldShowInputArea: Bool {
        switch entryPoint {
        case .connectivityTool, .chatHistory, .preLogin:
            return true
        case .helpAndSupport:
            return hasProceededToChat
        }
    }

    private(set) var hasProceededToChat: Bool = false
    private(set) var isExecutingAction: Bool = false

    /// `true` when the view model was seeded with a prior `chatID` — i.e. the merchant
    /// tapped a history row rather than starting fresh. Drives the "Continuing conversation"
    /// header in the chat surface.
    let isResumedChat: Bool

    var inputText: String = ""

    // MARK: - Private Properties

    private var chatID: Int64?
    private var sessionID: String?
    private let entryPoint: EntryPoint
    private let botSlug: String
    private let stores: StoresManager
    private var diagnosticsContext: [String: Any]?
    private let initialContext: [String: Any]?
    private let onContactHumanSupport: (_ transcript: String) -> Void
    var onStartJetpackSetup: () -> Void
    private let diagnosticsService: SupportDiagnosticsService

    // MARK: - Initialization

    init(botSlug: String = "woo-workflow-support_mobile_inapp_all_users",
         entryPoint: EntryPoint,
         stores: StoresManager = ServiceLocator.stores,
         initialContext: [String: Any]? = nil,
         diagnosticsService: SupportDiagnosticsService? = nil,
         chatID: Int64? = nil,
         onContactHumanSupport: @escaping (_ transcript: String) -> Void,
         onStartJetpackSetup: @escaping () -> Void = {}) {
        self.botSlug = botSlug
        self.entryPoint = entryPoint
        self.stores = stores
        self.initialContext = initialContext
        self.diagnosticsService = diagnosticsService ?? SupportDiagnosticsService()
        self.chatID = chatID
        self.isResumedChat = chatID != nil
        self.onContactHumanSupport = onContactHumanSupport
        self.onStartJetpackSetup = onStartJetpackSetup
    }

    // MARK: - Issue Selection & Diagnostics

    /// Selects an issue type and runs diagnostics if needed.
    ///
    func selectIssue(_ issue: SupportIssueType) async {
        selectedIssue = issue

        // Add user's selection as a message
        let userMessage = ChatMessage(role: .user, text: issue.displayName)
        messages.append(userMessage)

        // "Other" skips diagnostics and shows greeting
        guard issue != .other, let tests = issue.testsToRun else {
            let greetingMessage = ChatMessage(role: .bot, text: Localization.greetingMessage)
            messages.append(greetingMessage)
            hasProceededToChat = true
            return
        }

        // Initialize progress with all tests pending
        var testStatuses: [(test: SupportDiagnosticsService.Test, status: TestStatus)] = tests.map { ($0, .pending) }
        let progressMessage = ChatMessage(role: .bot, content: .diagnosticsProgress(testStatuses))
        messages.append(progressMessage)
        let progressIndex = messages.count - 1

        // Run each test sequentially, updating progress
        var failedResult: SupportDiagnosticsService.Result?

        for (index, test) in tests.enumerated() {
            // Mark current test as running
            testStatuses[index].status = .running
            messages[progressIndex] = ChatMessage(
                id: messages[progressIndex].id,
                role: .bot,
                content: .diagnosticsProgress(testStatuses)
            )

            // Run the test
            let results = await diagnosticsService.runTests([test])
            guard let result = results.first else { continue }

            diagnosticResults.append(result)

            if result.isSuccess {
                testStatuses[index].status = .passed
            } else {
                testStatuses[index].status = .failed(result.errorMessage)
                failedResult = result
                // Update progress to show failure
                messages[progressIndex] = ChatMessage(
                    id: messages[progressIndex].id,
                    role: .bot,
                    content: .diagnosticsProgress(testStatuses)
                )
                break
            }

            // Update progress
            messages[progressIndex] = ChatMessage(
                id: messages[progressIndex].id,
                role: .bot,
                content: .diagnosticsProgress(testStatuses)
            )
        }

        // Replace progress with final result
        if let failure = failedResult {
            messages[progressIndex] = ChatMessage(
                id: messages[progressIndex].id,
                role: .bot,
                content: .diagnosticsFailure(failure)
            )
        } else {
            messages[progressIndex] = ChatMessage(
                id: messages[progressIndex].id,
                role: .bot,
                content: .diagnosticsSuccess
            )
        }
    }

    /// Executes a fix action and re-runs the relevant test.
    ///
    func executeAction(_ action: SupportDiagnosticsService.Action) async {
        isExecutingAction = true
        defer { isExecutingAction = false }

        do {
            switch action {
            case .enableAnalytics:
                try await diagnosticsService.enableAnalytics()
                await rerunTest(.analyticsSetting)

            case .registerDevice:
                try await diagnosticsService.registerDevice()
                await rerunTest(.notifications)

            case .enableOrderNotifications(let settings):
                try await diagnosticsService.enableOrderNotifications(settings: settings)
                await rerunTest(.notifications)

            case .setupJetpack:
                onStartJetpackSetup()

            case .openNotificationSettings:
                if let selectedURL = diagnosticsService.openNotificationSettings(),
                   UIApplication.shared.canOpenURL(selectedURL) {
                    await UIApplication.shared.open(selectedURL)
                }
                replaceActionWithRetry()

            case .retryDiagnostics:
                await rerunAllTests()
            }
        } catch {
            DDLogError("⛔️ Failed to execute action \(action): \(error)")
        }
    }

    /// Replaces the current failure action with a retry action.
    ///
    func replaceActionWithRetry() {
        guard let messageIndex = messages.lastIndex(where: {
            if case .diagnosticsFailure = $0.content { return true }
            return false
        }),
              case .diagnosticsFailure(let result) = messages[messageIndex].content else {
            return
        }

        let updatedResult = SupportDiagnosticsService.Result(
            test: result.test,
            isSuccess: result.isSuccess,
            errorMessage: result.errorMessage,
            technicalDetails: result.technicalDetails,
            suggestedAction: .retryDiagnostics
        )

        messages[messageIndex] = ChatMessage(
            id: messages[messageIndex].id,
            role: .bot,
            content: .diagnosticsFailure(updatedResult)
        )
    }

    /// Re-runs a specific test and updates the results.
    ///
    private func rerunTest(_ test: SupportDiagnosticsService.Test) async {
        // Find the failure message and convert it to progress state
        guard let messageIndex = messages.lastIndex(where: {
            if case .diagnosticsFailure = $0.content { return true }
            return false
        }) else { return }

        let messageId = messages[messageIndex].id

        // Show progress state with the test running
        let progressSteps: [(test: SupportDiagnosticsService.Test, status: TestStatus)] = [(test, .running)]
        messages[messageIndex] = ChatMessage(
            id: messageId,
            role: .bot,
            content: .diagnosticsProgress(progressSteps)
        )

        // Run the test
        let newResults = await diagnosticsService.runTests([test])
        guard let newResult = newResults.first else { return }

        // Update diagnostic results
        if let index = diagnosticResults.firstIndex(where: { $0.test == test }) {
            diagnosticResults[index] = newResult
        }

        // Update message with result
        if newResult.isSuccess {
            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsSuccess
            )
        } else {
            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsFailure(newResult)
            )
        }
    }

    /// Re-runs all tests for the selected issue.
    ///
    private func rerunAllTests() async {
        guard let tests = selectedIssue?.testsToRun else { return }

        // Find the failure message to update
        guard let messageIndex = messages.lastIndex(where: {
            if case .diagnosticsFailure = $0.content { return true }
            return false
        }) else { return }

        let messageId = messages[messageIndex].id

        // Clear previous results
        diagnosticResults = []

        // Initialize progress with all tests pending
        var testStatuses: [(test: SupportDiagnosticsService.Test, status: TestStatus)] = tests.map { ($0, .pending) }
        messages[messageIndex] = ChatMessage(
            id: messageId,
            role: .bot,
            content: .diagnosticsProgress(testStatuses)
        )

        // Run each test sequentially, updating progress
        var failedResult: SupportDiagnosticsService.Result?

        for (index, test) in tests.enumerated() {
            // Mark current test as running
            testStatuses[index].status = .running
            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsProgress(testStatuses)
            )

            // Run the test
            let results = await diagnosticsService.runTests([test])
            guard let result = results.first else { continue }

            diagnosticResults.append(result)

            if result.isSuccess {
                testStatuses[index].status = .passed
            } else {
                testStatuses[index].status = .failed(result.errorMessage)
                failedResult = result
                messages[messageIndex] = ChatMessage(
                    id: messageId,
                    role: .bot,
                    content: .diagnosticsProgress(testStatuses)
                )
                break
            }

            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsProgress(testStatuses)
            )
        }

        // Replace progress with final result
        if let failure = failedResult {
            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsFailure(failure)
            )
        } else {
            messages[messageIndex] = ChatMessage(
                id: messageId,
                role: .bot,
                content: .diagnosticsSuccess
            )
        }
    }

    /// Proceeds from diagnostics results to chat, building context from diagnostics.
    ///
    func proceedToChat() {
        // Build context from diagnostic results
        var context: [String: Any] = initialContext ?? [:]

        if let issue = selectedIssue {
            context["issue_type"] = String(describing: issue)
        }

        if let troubleshootingDescription = SupportDiagnosticsService.troubleshootingDescription(from: diagnosticResults) {
            context["troubleshooting_results"] = troubleshootingDescription
        }

        if let site = stores.sessionManager.defaultSite {
            context["site_id"] = site.siteID
            context["site_url"] = site.url
        }

        context["app_version"] = Bundle.main.marketingVersion
        context["ios_version"] = UIDevice.current.systemVersion

        diagnosticsContext = context

        // Add greeting message to continue chat
        let greetingMessage = ChatMessage(role: .bot, text: Localization.postDiagnosticsGreeting)
        messages.append(greetingMessage)
        hasProceededToChat = true
    }

    // MARK: - Chat Actions

    func showGreeting() {
        guard messages.isEmpty else { return }

        // Resumed chats skip the greeting — the merchant is continuing a prior conversation.
        guard chatID == nil else { return }

        switch entryPoint {
        case .helpAndSupport:
            // Show issue picker as first message
            let pickerMessage = ChatMessage(
                role: .bot,
                content: .issuePicker(SupportIssueType.allCases)
            )
            messages.append(pickerMessage)

        case .connectivityTool, .preLogin:
            let greetingMessage = ChatMessage(role: .bot, text: Localization.greetingMessage)
            messages.append(greetingMessage)

        case .chatHistory:
            // Chat history loads via resumeIfNeeded() — no greeting needed
            break
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

        let userMessage = ChatMessage(role: .user, text: trimmedText)
        messages.append(userMessage)
        inputText = ""
        state = .sending

        // Use diagnostics context on first message, then nil for subsequent messages
        let context: [String: Any]? = {
            if chatID == nil {
                return diagnosticsContext ?? initialContext
            }
            return nil
        }()

        let wasNewChat = chatID == nil
        let firstUserMessage = trimmedText

        let action = SupportChatAction.sendMessage(
            botSlug: botSlug,
            message: trimmedText,
            chatID: chatID,
            sessionID: sessionID,
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

        return messages.compactMap { message -> String? in
            let roleName: String
            switch message.role {
            case .user: roleName = "User"
            case .bot: roleName = "Bot"
            case .unknown: roleName = "Unknown"
            }
            let timestamp = dateFormatter.string(from: message.timestamp)

            let contentText: String
            switch message.content {
            case .text(let text):
                contentText = text
            case .issuePicker:
                contentText = "[Issue picker shown]"
            case .diagnosticsProgress(let steps):
                let summary = steps.map { "\($0.test.title): \($0.status)" }.joined(separator: ", ")
                contentText = "[Running diagnostics: \(summary)]"
            case .diagnosticsSuccess:
                contentText = "[All diagnostics passed]"
            case .diagnosticsFailure(let result):
                contentText = "[Diagnostics failed: \(result.test.title) - \(result.errorMessage ?? "Unknown error")]"
            }

            return "[\(timestamp)] \(roleName): \(contentText)"
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
            sessionID = response.sessionID
            persistChatBookmark(wasNewChat: wasNewChat,
                                response: response,
                                firstUserMessage: firstUserMessage)

            if let lastBotMessage = response.messages.last(where: { $0.role == .bot }) {
                /// Skips displaying last bot message when human support is required. User is suggested to contact support manually.
                if let flags = lastBotMessage.context?.flags, flags.forwardToHumanSupport {
                    shouldPromptHumanSupport = true
                } else {
                    let assistantMessage = ChatMessage(
                        role: .bot,
                        text: lastBotMessage.content
                    )
                    messages.append(assistantMessage)
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
            sessionID = response.sessionID
            let rehydrated: [ChatMessage] = response.messages.compactMap { message in
                switch message.role {
                case .user:
                    return ChatMessage(role: .user, text: message.content)
                case .bot:
                    return ChatMessage(role: .bot, text: message.content)
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
        static let postDiagnosticsGreeting = NSLocalizedString(
            "supportChatViewModel.postDiagnosticsGreeting",
            value: "Please describe your issue in more detail so I can help.",
            comment: "Message prompting user to describe their issue after diagnostics"
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
