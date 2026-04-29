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

    /// Current phase of the support chat flow.
    ///
    enum Phase: Equatable {
        case issuePicker
        case runningDiagnostics
        case showingResults
        case chatting
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

    private(set) var phase: Phase
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

        // Set initial phase based on entry point
        switch entryPoint {
        case .helpAndSupport:
            self.phase = .issuePicker
        case .connectivityTool:
            self.phase = .chatting
        }
    }

    // MARK: - Issue Selection & Diagnostics

    /// Selects an issue type and runs diagnostics if needed.
    ///
    func selectIssue(_ issue: SupportIssueType) async {
        selectedIssue = issue

        // "Other" skips diagnostics and goes directly to chat
        guard issue != .other else {
            phase = .chatting
            return
        }

        phase = .runningDiagnostics
        diagnosticResults = await diagnosticsService.runTests(for: issue)
        phase = .showingResults
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

    /// Proceeds from results screen to chat, building context from diagnostics.
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
        phase = .chatting
    }

    // MARK: - Chat Actions

    func showGreeting() {
        guard messages.isEmpty else { return }
        state = .sending

        Task {
            try? await Task.sleep(for: .seconds(1))
            let greetingMessage = ChatMessage(role: .bot, content: Localization.greetingMessage)
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

    private func handleSendMessageResult(_ result: Result<SupportChatResponse, Error>) {
        switch result {
        case .success(let response):
            chatID = response.chatID

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
