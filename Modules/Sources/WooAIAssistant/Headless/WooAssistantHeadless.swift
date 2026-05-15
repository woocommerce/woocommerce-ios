import Foundation
import CocoaLumberjackSwift
import NetworkingCore

/// Headless test driver for the WooCommerce AI Assistant. Wires the same
/// `AgenticChatBackend`, REST tool registry, and safety policy that the
/// app target ships with, but reads dependencies from caller-supplied
/// credentials so smoke runs and unit tests can drive real conversations
/// without `ServiceLocator`, `Networking`, or any SwiftUI surface.
///
/// Each harness instance owns one long-lived `AgenticChatBackend`, so successive
/// `send(_:)` calls share its `TranscriptStore` and accumulate multi-turn memory
/// just like the in-app chat surface. Each harness instance also owns its own
/// `WpComJetpackAIJWTProvider`, so two concurrent instances against the same
/// merchant will each mint a JWT (one extra mint per instance). Smoke runs
/// typically have one instance.
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

        /// One card the orchestrator authorized for render via a `.cardRender`
        /// event. `kind` and `toolName` carry the orchestrator's synthetic tool
        /// name (e.g. `show_cards.order`, `analytics_orders`). `payloadJSON` is
        /// the canonical JSON encoding of the rendered card payload, identical
        /// to what `MessageCardHost` would receive in the SwiftUI surface.
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

        /// Every card the orchestrator authorized for render this turn, in
        /// emission order, deduped first-wins by `(family, id)` to mirror the
        /// SwiftUI surface. A turn whose tools never emit `.cardRender` (e.g. a
        /// bare `orders_list` or `analytics_orders`) yields an empty list here.
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
    private let backend: AgenticChatBackend

    // MARK: - Init

    /// Production wiring: real URLSession-backed transports talking to
    /// `jetpack-ai-query` and the merchant's store.
    public init(credentials: Credentials,
                configuration: Configuration = .init()) {
        let normalizedSiteURL = Self.normalizeSiteURL(credentials.siteURL)
        let basicAuthHeader = Self.basicAuthHeader(username: credentials.username, appPassword: credentials.appPassword)
        let session = URLSession.shared
        let jwtProvider = WpComJetpackAIJWTProvider(blogID: credentials.siteID) { _ in
            try await Self.mintJetpackAIJWT(siteURL: normalizedSiteURL,
                                            basicAuthHeader: basicAuthHeader,
                                            session: session)
        }
        let chatService = JetpackAIQueryClient(jwtProvider: jwtProvider)
        let restClient = HeadlessURLSessionWCRESTClient(siteURL: normalizedSiteURL,
                                                        basicAuthHeader: basicAuthHeader,
                                                        session: session)
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
        let toolRegistry = RESTToolRegistry(client: restClient, tools: Self.allTools())
        let prompt = configuration.systemPrompt
        let resolver = DefaultConfirmationSnapshotResolver(client: restClient)
        self.backend = AgenticChatBackend(
            chatService: chatService,
            toolRegistry: toolRegistry,
            safetyPolicy: DefaultSafetyPolicy(snapshotResolver: resolver),
            systemPromptProvider: { prompt },
            maxIterations: configuration.maxIterations
        )
    }

    // MARK: - Driving a turn

    /// Send one user prompt through the long-lived `AgenticChatBackend` and collect
    /// the full turn result. Successive calls share the backend's transcript so
    /// the harness sees the same multi-turn memory the in-app chat surface does.
    /// Optionally override confirmation handling via `resolveConfirmation`; when
    /// nil, `configuration.defaultConfirmationPolicy` applies.
    public func send(_ message: String,
                     resolveConfirmation: ConfirmationResolver? = nil) async throws -> ConversationTurnResult {
        var result = ConversationTurnResult()
        // Tool calls land via `.toolCallStarted` before their `.toolCallCompleted`; index by id so
        // the completed event can attach the result to the same record without rebuilding the array.
        var toolCallIndexByID: [String: Int] = [:]
        // The orchestrator emits a synthetic `.toolResult` immediately before each `.cardRender`.
        // Buffer those payloads so the `.cardRender` arm can pick the right one up.
        var pendingCardPayloads: [String: PendingCardPayload] = [:]
        var cardKeysSeen: Set<SyntheticCardKey> = []
        let policy = configuration.defaultConfirmationPolicy

        let turn = AssistantTurn(prompt: message)
        let context = AssistantContext(
            siteID: credentials.siteID,
            siteURL: Self.normalizeSiteURL(credentials.siteURL),
            blogID: credentials.siteID
        )

        let stream = backend.send(turn: turn, context: context, session: nil)
        for try await yield in stream {
            guard case .event(let event) = yield else { continue }
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

            case .toolResult(let toolCallID, let toolName, let payload):
                // Only synthetic toolResults (paired with a cardRender) carry render payloads;
                // the model-visible toolResult that precedes them has a non-card-shaped ID.
                if Self.parseSyntheticCardID(toolCallID) != nil {
                    pendingCardPayloads[toolCallID] = PendingCardPayload(
                        toolName: toolName,
                        payloadJSON: Self.encodeJSON(payload)
                    )
                }

            case .cardRender(let toolCallID):
                guard let pending = pendingCardPayloads.removeValue(forKey: toolCallID),
                      let key = Self.parseSyntheticCardID(toolCallID) else { continue }
                let record = ConversationTurnResult.CardRecord(kind: pending.toolName,
                                                               toolName: pending.toolName,
                                                               payloadJSON: pending.payloadJSON)
                if !cardKeysSeen.contains(key) {
                    cardKeysSeen.insert(key)
                    result.cards.append(record)
                }

            case .confirmationRequired(let proposal):
                let flatPreview = proposal.preview.flattenedSummary()
                let pending = PendingConfirmation(
                    toolName: proposal.toolName,
                    preview: flatPreview,
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
                    preview: flatPreview,
                    decision: decisionLabel
                ))
                if approved {
                    await backend.confirmProposal(proposal.id)
                } else {
                    await backend.cancelProposal(proposal.id)
                }

            case .confirmationResolved:
                // Already reflected in the confirmation record above.
                break

            case .failed(let error):
                result.failureMessage = error.message

            case .completed, .terminated:
                break
            }
        }

        return result
    }

    // MARK: - Helpers

    private struct PendingCardPayload: Sendable {
        let toolName: String
        let payloadJSON: String
    }

    private struct SyntheticCardKey: Hashable {
        let family: String
        let entityID: String
    }

    /// Parses the orchestrator's synthetic toolCallID `<callID>:card:<index>:<family>:<id>`.
    /// Mirrors `MessageBubble.cardKey(fromSyntheticToolCallID:)` so the harness applies the
    /// same `(family, id)` dedupe as the SwiftUI surface. Returns nil for any other shape.
    private static func parseSyntheticCardID(_ toolCallID: String) -> SyntheticCardKey? {
        let parts = toolCallID.split(separator: ":", omittingEmptySubsequences: false)
        guard let markerIndex = parts.indices.first(where: { parts[$0] == "card" }),
              let entityIDStartIndex = parts.index(markerIndex, offsetBy: 3, limitedBy: parts.endIndex),
              entityIDStartIndex < parts.endIndex else {
            return nil
        }
        let familyIndex = parts.index(markerIndex, offsetBy: 2)
        let entityID = parts[entityIDStartIndex...].joined(separator: ":")
        guard !parts[familyIndex].isEmpty, !entityID.isEmpty else { return nil }
        return SyntheticCardKey(family: String(parts[familyIndex]),
                                entityID: entityID)
    }

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

    /// Builds the HTTP Basic auth header from a WP user + application password.
    /// Strips whitespace from the app password before encoding - Atomic-hosted WC REST
    /// and the Jetpack mint endpoint reject spaced "abcd efgh" passwords with a 401
    /// even though wp-admin accepts them.
    private static func basicAuthHeader(username: String, appPassword: String) -> String {
        let stripped = appPassword.replacingOccurrences(of: " ", with: "")
        let raw = "\(username):\(stripped)"
        let encoded = Data(raw.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    /// POSTs to `<siteURL>/wp-json/jetpack/v4/jetpack-ai-jwt` over Basic auth and
    /// extracts the minted token. The harness lives outside the Jetpack tunnel,
    /// so the merchant's app password is the only viable credential.
    private static func mintJetpackAIJWT(siteURL: URL,
                                         basicAuthHeader: String,
                                         session: URLSession) async throws -> String {
        let endpoint = siteURL.appendingPathComponent("wp-json/jetpack/v4/jetpack-ai-jwt")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AssistantError(kind: .network, message: "Headless JWT mint received a non-HTTP response.")
        }
        if !(200..<300).contains(http.statusCode) {
            let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
            throw AssistantError(kind: .auth,
                                 code: String(http.statusCode),
                                 message: "Headless JWT mint failed (HTTP \(http.statusCode)): \(snippet)")
        }
        struct Envelope: Decodable {
            let token: String?
            let jwt: String?
        }
        do {
            let decoded = try JSONDecoder().decode(Envelope.self, from: data)
            if let token = decoded.token, !token.isEmpty { return token }
            if let jwt = decoded.jwt, !jwt.isEmpty { return jwt }
        } catch {
            DDLogError("WooAssistantHeadless mint envelope decode failed: \(error)")
        }
        let snippet = String(data: data.prefix(500), encoding: .utf8) ?? ""
        throw AssistantError(kind: .auth,
                             message: "Headless JWT mint expected `token` in response body, got: \(snippet)")
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
            ProductVariationsBulkUpdateTool.make(),
            CustomersListTool.make(),
            AnalyticsOrdersTool.make(),
            ShowCardsTool.make()
        ]
    }
}

// MARK: - URLSession-backed REST transport

/// `WCRESTClient` that talks straight to a WooCommerce store's `/wp-json/...`
/// endpoints using HTTP Basic auth. The harness deliberately avoids the
/// `Networking` module so it can run outside the Jetpack tunnel.
///
/// Non-2xx responses are returned to the caller as `WCRESTResponse(statusCode: ...)`
/// per the protocol contract, not thrown. The struct is fileprivate to keep the
/// harness as the only consumer; the chat loop sees it through `WCRESTClient`.
private struct HeadlessURLSessionWCRESTClient: WCRESTClient {

    private let siteURL: URL
    private let basicAuthHeader: String
    private let session: URLSession

    init(siteURL: URL, basicAuthHeader: String, session: URLSession) {
        self.siteURL = siteURL
        self.basicAuthHeader = basicAuthHeader
        self.session = session
    }

    func request(method: String,
                 path: String,
                 query: [String: String]?,
                 body: Data?) async -> WCRESTResponse {
        let url: URL
        do {
            url = try buildURL(path: path, query: query)
        } catch {
            DDLogError("HeadlessURLSessionWCRESTClient buildURL failed: \(error)")
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        if let body, !body.isEmpty {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
            }
            return WCRESTResponse(data: data,
                                  statusCode: http.statusCode,
                                  headers: Self.flattenHeaders(http.allHeaderFields))
        } catch {
            DDLogError("HeadlessURLSessionWCRESTClient transport failed: \(error)")
            return WCRESTResponse(data: Data(), statusCode: HTTPStatusClassification.transportFailure)
        }
    }

    private func buildURL(path: String, query: [String: String]?) throws -> URL {
        let trimmedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let fullPath = "wp-json/\(trimmedPath)"
        guard var components = URLComponents(
            url: siteURL.appendingPathComponent(fullPath),
            resolvingAgainstBaseURL: false
        ) else {
            throw HeadlessURLSessionWCRESTError.invalidURL
        }
        if let query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw HeadlessURLSessionWCRESTError.invalidURL
        }
        return url
    }

    private static func flattenHeaders(_ raw: [AnyHashable: Any]) -> [String: String] {
        var out: [String: String] = [:]
        for (key, value) in raw {
            if let stringKey = key as? String, let stringValue = value as? String {
                out[stringKey] = stringValue
            }
        }
        return out
    }
}

private enum HeadlessURLSessionWCRESTError: Error {
    case invalidURL
}
