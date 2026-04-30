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

    /// Loads credentials from `/tmp/woo-ai-smoke-store.env`. The smoke skill
    /// stages this file from `~/.woo-ai-smoke/store.env` (the engineer-owned
    /// source of truth) at run-start, because the iOS simulator process
    /// sandboxes `~` to its own container and cannot read the host's home
    /// directly. The trap cleanup deletes the `/tmp` copy at run-end.
    /// Returns nil when the file is missing or any required key is absent so
    /// smoke runs that lack credentials skip without failing the test build.
    public nonisolated static func credentialsFromStoreEnv() -> Credentials? {
        let path = "/tmp/woo-ai-smoke-store.env"
        guard let env = try? parseDotenv(at: URL(fileURLWithPath: path)) else { return nil }
        guard let siteURL = env["WOO_SITE_URL"],
              let siteIDString = env["WOO_SITE_ID"], let siteID = Int64(siteIDString),
              let username = env["WOO_USERNAME"],
              let appPassword = env["WOO_APP_PASSWORD"] else { return nil }
        return Credentials(siteURL: siteURL,
                           siteID: siteID,
                           username: username,
                           appPassword: appPassword)
    }

    private static func parseDotenv(at url: URL) throws -> [String: String] {
        let raw = try String(contentsOf: url, encoding: .utf8)
        var out: [String: String] = [:]
        for line in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"),
                  let eq = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<eq]).trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: eq)...])
                .trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            out[key] = value
        }
        return out
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

    /// Plain-Swift snapshot of a single headless conversation turn. The harness
    /// drains the orchestrator's event stream once and folds it into this shape so
    /// XCTest / Swift Testing assertions can reach the merchant text, every tool
    /// dispatch, every card payload, and every confirmation decision without
    /// touching SwiftUI or Combine.
    ///
    /// All fields are JSON-serializable values (strings, structs of strings) so
    /// downstream smoke runners can persist a turn record to disk and replay it
    /// against stored baselines.
    public struct ConversationTurnResult: Sendable, Equatable {

        /// One tool dispatch as observed by the harness. `argumentsJSON` is the
        /// raw model-emitted argument string. `resultJSON` is the JSON payload
        /// the loop fed back to the model on the next turn (or the cached-replay
        /// envelope for de-duped calls). `errorMessage` carries a typed-error
        /// reason when the dispatch failed before producing a payload.
        public struct ToolCallRecord: Sendable, Equatable {
            public let name: String
            public let argumentsJSON: String
            public var resultJSON: String?
            public var errorMessage: String?

            public init(name: String,
                        argumentsJSON: String,
                        resultJSON: String? = nil,
                        errorMessage: String? = nil) {
                self.name = name
                self.argumentsJSON = argumentsJSON
                self.resultJSON = resultJSON
                self.errorMessage = errorMessage
            }
        }

        /// One structured tool payload captured from a `.toolResult` event. `kind`
        /// is the tool name on trunk (e.g. `show_cards`, `orders_list`) since the
        /// orchestrator no longer carries a separate result-kind tag.
        /// `payloadJSON` is the canonical JSON encoding of the structured payload
        /// the model received on its next turn.
        public struct CardRecord: Sendable, Equatable {
            public let kind: String
            public let toolName: String
            public let payloadJSON: String

            public init(kind: String, toolName: String, payloadJSON: String) {
                self.kind = kind
                self.toolName = toolName
                self.payloadJSON = payloadJSON
            }
        }

        /// One safety-policy confirmation as observed by the harness. `decision`
        /// reflects the resolver's verdict (`approved`, `declined`) or the policy
        /// fallback when no resolver was supplied (`auto-approved`,
        /// `auto-declined`).
        public struct ConfirmationRecord: Sendable, Equatable {
            public let toolName: String
            public let classification: String
            public let preview: String
            public let decision: String

            public init(toolName: String,
                        classification: String,
                        preview: String,
                        decision: String) {
                self.toolName = toolName
                self.classification = classification
                self.preview = preview
                self.decision = decision
            }
        }

        /// Concatenated assistant prose across the whole turn.
        public var assistantText: String

        /// Every tool dispatched by the loop, in call order.
        public var toolCalls: [ToolCallRecord]

        /// Every `.toolResult` payload captured during the turn. Trunk emits one
        /// per tool with a structured success payload, so this list mirrors the
        /// successful-dispatch subset of `toolCalls`.
        public var cards: [CardRecord]

        /// Every confirmation surfaced and how it resolved.
        public var confirmations: [ConfirmationRecord]

        /// Set when the orchestrator yielded `.failed`. Nil on a clean turn.
        public var failureMessage: String?

        public init(assistantText: String = "",
                    toolCalls: [ToolCallRecord] = [],
                    cards: [CardRecord] = [],
                    confirmations: [ConfirmationRecord] = [],
                    failureMessage: String? = nil) {
            self.assistantText = assistantText
            self.toolCalls = toolCalls
            self.cards = cards
            self.confirmations = confirmations
            self.failureMessage = failureMessage
        }
    }

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
