import Foundation
import CocoaLumberjackSwift

/// Headless test driver for the WooCommerce AI Assistant. Wires the same
/// `AgenticLoopOrchestrator`, REST tool registry, and safety policy that the
/// app target ships with, but reads dependencies from caller-supplied
/// credentials so smoke runs and unit tests can drive real conversations
/// without `ServiceLocator`, `Networking`, or any SwiftUI surface.
///
/// Each `send(_:)` call builds a fresh orchestrator so the harness is
/// stateless from the caller's perspective - no shared session, no carry-over
/// safety state. The JWT cache is the one piece of cross-call state and lives
/// process-wide on `URLSessionJetpackAIJWTClient` so concurrent harness
/// instances against the same merchant share one minted token.
public actor WooAssistantHeadless {

    // MARK: - Public types

    public struct Credentials: Sendable {
        public let siteURL: String
        public let siteID: Int64
        public let username: String
        public let appPassword: String

        public init(siteURL: String,
                    siteID: Int64,
                    username: String,
                    appPassword: String) {
            self.siteURL = siteURL
            self.siteID = siteID
            self.username = username
            self.appPassword = appPassword
        }
    }

    /// Loads credentials from `/tmp/woo-ai-assistant-credentials.json` (the path
    /// the smoke skill writes). Returns nil when the file is missing or malformed
    /// so smoke runs that lack credentials skip without failing the test build.
    public nonisolated static func credentialsFromEnvironmentOrFile() -> Credentials? {
        let path = "/tmp/woo-ai-assistant-credentials.json"
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        struct Stored: Decodable {
            let siteURL: String
            let siteID: Int64
            let username: String
            let appPassword: String
        }
        guard let stored = try? JSONDecoder().decode(Stored.self, from: data) else { return nil }
        return Credentials(siteURL: stored.siteURL,
                           siteID: stored.siteID,
                           username: stored.username,
                           appPassword: stored.appPassword)
    }

    public struct Configuration: Sendable {
        public var maxIterations: Int
        public var readOnlyMode: Bool
        public var systemPrompt: String
        public var defaultConfirmationPolicy: DefaultConfirmationPolicy

        public init(maxIterations: Int = 12,
                    readOnlyMode: Bool = false,
                    systemPrompt: String = AssistantSystemPrompt.build(),
                    defaultConfirmationPolicy: DefaultConfirmationPolicy = .alwaysDecline) {
            self.maxIterations = maxIterations
            self.readOnlyMode = readOnlyMode
            self.systemPrompt = systemPrompt
            self.defaultConfirmationPolicy = defaultConfirmationPolicy
        }
    }

    public enum DefaultConfirmationPolicy: Sendable {
        /// Approve every confirmation. For tests that must exercise the
        /// destructive code path.
        case alwaysApprove
        /// Decline every confirmation. Safe default - a misbehaving model
        /// can't issue a real refund.
        case alwaysDecline
    }

    /// Plain-Swift mirror of `ToolProposal` exposed to test resolvers so
    /// callers don't need `@testable import` to script confirmations.
    public struct PendingConfirmation: Sendable, Equatable {
        public let toolName: String
        public let preview: String
        public let classification: String

        public init(toolName: String, preview: String, classification: String) {
            self.toolName = toolName
            self.preview = preview
            self.classification = classification
        }
    }

    public enum ConfirmationDecision: Sendable, Equatable {
        case approve
        case decline
    }

    public typealias ConfirmationResolver = @Sendable (PendingConfirmation) -> ConfirmationDecision

    // MARK: - State

    private let credentials: Credentials
    private let configuration: Configuration
    private let chatService: AIChatService
    private let restClient: WCRESTClient

    // MARK: - Init

    /// Production wiring: real URLSession-backed transports talking to
    /// `jetpack-ai-query` and the merchant's store.
    public init(credentials: Credentials,
                configuration: Configuration = .init()) {
        let normalizedSiteURL = Self.normalizeSiteURL(credentials.siteURL)
        let jwtProvider = URLSessionJetpackAIJWTClient(
            siteURL: normalizedSiteURL,
            blogID: credentials.siteID,
            username: credentials.username,
            appPassword: credentials.appPassword
        )
        let chatService = JetpackAIQueryClient(jwtProvider: jwtProvider)
        let restClient = URLSessionWCRESTClient(
            siteURL: normalizedSiteURL,
            auth: .appPassword(user: credentials.username, key: credentials.appPassword)
        )
        self.init(credentials: credentials,
                  configuration: configuration,
                  chatService: chatService,
                  restClient: restClient)
    }

    // Internal seam used by the test target to inject a mock chat service and a stub REST client.
    init(credentials: Credentials,
         configuration: Configuration,
         chatService: AIChatService,
         restClient: WCRESTClient) {
        self.credentials = credentials
        self.configuration = configuration
        self.chatService = chatService
        self.restClient = restClient
    }

    // MARK: - Driving a turn

    /// Send one user prompt through a freshly-built orchestrator and collect
    /// the full turn result. Optionally override confirmation handling via
    /// `resolveConfirmation`; when nil, `configuration.defaultConfirmationPolicy`
    /// applies.
    public func send(_ message: String,
                     resolveConfirmation: ConfirmationResolver? = nil) async throws -> ConversationTurnResult {
        let toolRegistry = RESTToolRegistry(client: restClient, tools: Self.allTools())
        let orchestrator = AgenticLoopOrchestrator(
            chatService: chatService,
            toolRegistry: toolRegistry,
            safetyPolicy: DefaultSafetyPolicy(),
            systemPrompt: configuration.systemPrompt,
            maxIterations: configuration.maxIterations
        )

        var result = ConversationTurnResult()
        // Tool calls land via `.toolCallStarted` before their `.toolCallCompleted`; index by id so
        // the completed event can attach the result to the same record without rebuilding the array.
        var toolCallIndexByID: [String: Int] = [:]
        let policy = configuration.defaultConfirmationPolicy

        let stream = orchestrator.run(prompt: message)
        for try await event in stream {
            switch event {
            case .textChunk(let text):
                result.assistantText += text

            case .toolCallStarted(let id, let name, let argumentsJSON):
                let record = ConversationTurnResult.ToolCallRecord(
                    name: name,
                    argumentsJSON: argumentsJSON ?? ""
                )
                toolCallIndexByID[id] = result.toolCalls.count
                result.toolCalls.append(record)

            case .toolCallCompleted(let id, _, let resultJSON):
                if let index = toolCallIndexByID[id] {
                    result.toolCalls[index].resultJSON = resultJSON
                }

            case .toolResult(_, let toolName, let payload):
                let payloadJSON = Self.encodeJSON(payload)
                result.cards.append(.init(kind: toolName,
                                          toolName: toolName,
                                          payloadJSON: payloadJSON))

            case .cardRender:
                // The headless harness records raw `toolResult` payloads above; the
                // separate `cardRender` UI hint is meaningful only in the SwiftUI layer.
                break

            case .confirmationRequired(let proposal):
                let pending = PendingConfirmation(
                    toolName: proposal.toolName,
                    preview: proposal.preview,
                    classification: Self.classificationString(for: proposal.toolName)
                )
                let approved: Bool
                let decisionLabel: String
                if configuration.readOnlyMode {
                    // readOnlyMode hard-denies every confirmation regardless of resolver/policy.
                    approved = false
                    decisionLabel = "declined"
                } else if let resolver = resolveConfirmation {
                    let decision = resolver(pending)
                    approved = decision == .approve
                    decisionLabel = approved ? "approved" : "declined"
                } else {
                    switch policy {
                    case .alwaysApprove:
                        approved = true
                        decisionLabel = "auto-approved"
                    case .alwaysDecline:
                        approved = false
                        decisionLabel = "auto-declined"
                    }
                }
                result.confirmations.append(.init(
                    toolName: proposal.toolName,
                    classification: pending.classification,
                    preview: proposal.preview,
                    decision: decisionLabel
                ))
                if approved {
                    await orchestrator.confirm(proposalID: proposal.id)
                } else {
                    await orchestrator.cancel(proposalID: proposal.id)
                }

            case .confirmationResolved:
                // Already reflected in the confirmation record above.
                break

            case .failed(let error):
                result.failureMessage = error.message

            case .completed:
                break
            }
        }

        return result
    }

    // MARK: - Helpers

    private static func encodeJSON(_ value: AnyCodableJSON) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            DDLogError("WooAssistantHeadless failed to encode tool payload: \(error)")
            return "{}"
        }
    }

    private static func classificationString(for toolName: String) -> String {
        // Trunk's safety surface only distinguishes safe vs unsafe; reaching the resolver path
        // implies unsafe. Keep the string typed so future safety taxonomies plug in cleanly.
        switch toolName {
        case OrdersBulkUpdateTool.name, ProductsBulkUpdateTool.name:
            return "unsafe-bulk"
        default:
            return "unsafe"
        }
    }

    private static func normalizeSiteURL(_ raw: String) -> URL {
        if let url = URL(string: raw) { return url }
        // Intentionally fall back to a placeholder rather than fail loudly: a misconfigured
        // credential file should surface as the eventual mint or REST call returning a typed
        // error, not a constructor crash that kills the whole smoke run.
        DDLogError("WooAssistantHeadless could not parse siteURL `\(raw)`; using empty placeholder.")
        return URL(string: "about:blank") ?? URL(fileURLWithPath: "/")
    }

    /// Production REST tool catalog. Mirrors what the app target wires into its
    /// `AgenticLoopOrchestrator`. Tests inject a different list when they need
    /// to simulate a single-tool subset.
    static func allTools() -> [RESTTool] {
        [
            OrdersListTool.make(),
            OrdersGetTool.make(),
            OrdersUpdateTool.make(),
            OrdersBulkUpdateTool.make(),
            ProductsListTool.make(),
            ProductsGetTool.make(),
            ProductsUpdateTool.make(),
            ProductsBulkUpdateTool.make(),
            ProductVariationsListTool.make(),
            ProductVariationsUpdateTool.make(),
            CustomersListTool.make(),
            AnalyticsRevenueTool.make(),
            AnalyticsOrdersTool.make(),
            ShowCardsTool.make()
        ]
    }
}
