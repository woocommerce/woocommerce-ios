import Foundation
import Observation
import UIKit
import Yosemite
import enum Networking.SupportChatRole
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

    /// URL to open when a fix action requires opening settings.
    ///
    private(set) var selectedURL: URL?

    /// Set to true when the user needs to start Jetpack setup.
    ///
    private(set) var shouldStartJetpackSetup: Bool = false

    /// Whether the input area should be shown.
    /// Hidden during issue picker and diagnostics phases.
    ///
    var shouldShowInputArea: Bool {
        switch entryPoint {
        case .connectivityTool:
            return true
        case .helpAndSupport:
            return hasProceededToChat
        }
    }

    private(set) var hasProceededToChat: Bool = false

    var inputText: String = ""

    // MARK: - Private Properties

    private var chatID: Int64?
    private let entryPoint: EntryPoint
    private let botSlug: String
    private let stores: StoresManager
    private var diagnosticsContext: [String: Any]?
    private let initialContext: [String: Any]?
    private let onContactHumanSupport: (_ transcript: String) -> Void
    private let diagnosticsService: SupportDiagnosticsService

    // MARK: - Initialization

    init(botSlug: String = "woo-workflow-support_mobile_inapp",
         entryPoint: EntryPoint = .helpAndSupport,
         stores: StoresManager = ServiceLocator.stores,
         initialContext: [String: Any]? = nil,
         diagnosticsService: SupportDiagnosticsService? = nil,
         onContactHumanSupport: @escaping (_ transcript: String) -> Void) {
        self.botSlug = botSlug
        self.entryPoint = entryPoint
        self.stores = stores
        self.initialContext = initialContext
        self.diagnosticsService = diagnosticsService ?? SupportDiagnosticsService()
        self.onContactHumanSupport = onContactHumanSupport
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
                shouldStartJetpackSetup = true

            case .openNotificationSettings:
                selectedURL = diagnosticsService.openNotificationSettings()
            }
        } catch {
            DDLogError("⛔️ Failed to execute action \(action): \(error)")
        }
    }

    /// Re-runs a specific test and updates the results.
    ///
    private func rerunTest(_ test: SupportDiagnosticsService.Test) async {
        let newResults = await diagnosticsService.runTests([test])
        if let newResult = newResults.first,
           let index = diagnosticResults.firstIndex(where: { $0.test == test }) {
            diagnosticResults[index] = newResult
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

        switch entryPoint {
        case .helpAndSupport:
            // Show issue picker as first message
            let pickerMessage = ChatMessage(
                role: .bot,
                content: .issuePicker(SupportIssueType.allCases)
            )
            messages.append(pickerMessage)

        case .connectivityTool:
            // Show standard greeting for connectivity tool entry
            let greetingMessage = ChatMessage(role: .bot, text: Localization.greetingMessage)
            messages.append(greetingMessage)
        }
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

        let action = SupportChatAction.sendMessage(
            botSlug: botSlug,
            message: trimmedText,
            chatID: chatID,
            context: context
        ) { [weak self] result in
            self?.handleSendMessageResult(result)
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

    private func handleSendMessageResult(_ result: Result<SupportChatResponse, Error>) {
        switch result {
        case .success(let response):
            chatID = response.chatID

            if let lastBotMessage = response.messages.last(where: { $0.role == .bot }) {
                let assistantMessage = ChatMessage(
                    role: .bot,
                    text: lastBotMessage.content
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
    }
}
