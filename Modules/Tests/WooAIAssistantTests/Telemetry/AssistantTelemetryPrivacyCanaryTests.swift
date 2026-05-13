import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantTelemetryPrivacyCanaryTests {

    private let context = AssistantTelemetryContext(
        conversationID: "11111111-1111-4111-8111-111111111111",
        requestID: "22222222-2222-4222-8222-222222222222",
        messageID: "33333333-3333-4333-8333-333333333333"
    )

    /// Substrings whose appearance inside a collected string value signals the payload is leaking
    /// raw content. Matched case-insensitively, so partials like `error_description` trip on
    /// `description` and `entity_identifiers` trips on `identifiers`.
    private static let denylist: [String] = [
        "summary", "prompts", "model_completions", "transcripts", "embeddings", "hashes",
        "entity_identifiers", "merchant_business_data",
        "prompt_text", "response_body", "content_body", "payload_body",
        "args_json", "arguments_json", "result_payload",
        "ui_structured_raw", "stack_trace", "validation_reasons", "provider_response",
        "address", "phone",
        "callback_arguments", "callback_payload", "deep_link",
        "error_message", "error_description", "exception"
    ]

    private static let canonicalIdentifierRegex = try! NSRegularExpression(
        pattern: "^[a-z][a-z0-9_]*$",
        options: []
    )

    private static let uuidRegex = try! NSRegularExpression(
        pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        options: [.caseInsensitive]
    )

    /// Tokens that an adversarial value would carry to indicate raw content slipped through the
    /// typed enum boundaries. The walker fails whenever a collected string contains any of them.
    private static let contentLeakRegex = try! NSRegularExpression(
        pattern: "(@|https?:|\\.com\\b|\\.net\\b|\\.org\\b|sku-|coupon_)",
        options: [.caseInsensitive]
    )

    private static let knownConstants: Set<String> = [
        AssistantTelemetryConstants.completionStack,
        AssistantTelemetryConstants.promptVersion,
        AssistantTelemetryConstants.toolCatalogVersion
    ]

    @Test
    func test_every_event_payload_only_carries_bounded_typed_fields() {
        let events: [AssistantTelemetryEvent] = [
            .conversationStarted(context: context),
            .turnStarted(context: context,
                         isRetry: false,
                         completionStack: AssistantTelemetryConstants.completionStack,
                         promptVersion: AssistantTelemetryConstants.promptVersion,
                         toolCatalogVersion: AssistantTelemetryConstants.toolCatalogVersion),
            .toolCallCompleted(context: context,
                               toolName: "orders_list",
                               status: .success,
                               errorKind: nil,
                               durationMs: 42),
            .toolCallCompleted(context: context,
                               toolName: "orders_update",
                               status: .failure,
                               errorKind: .validationError,
                               durationMs: nil),
            .toolCallCompleted(context: context,
                               toolName: "unknown",
                               status: .failure,
                               errorKind: .validationError,
                               durationMs: nil),
            .showCardsProcessed(context: context,
                                requestedCount: 3,
                                renderedCount: 1,
                                missingCount: 1,
                                rejectedCount: 1),
            .cardTapped(context: context,
                        cardFamily: .order,
                        actionFamily: .openOrder),
            .turnCompleted(context: context,
                           outcome: .failed,
                           durationMs: 999,
                           errorKind: .network,
                           isRetry: false,
                           completionStack: AssistantTelemetryConstants.completionStack,
                           promptVersion: AssistantTelemetryConstants.promptVersion,
                           toolCatalogVersion: AssistantTelemetryConstants.toolCatalogVersion)
        ]

        for event in events {
            let result = Self.checkEvent(event)
            #expect(result.isAllowed,
                    "event \(event) leaked: \(result.reason ?? "unknown")")
        }
    }

    @Test
    func test_canary_when_event_carries_adversarial_content_then_reports_leak() {
        // Given an event whose tool_name is an attacker-controlled string that escaped canonicalization
        let adversarial: AssistantTelemetryEvent = .toolCallCompleted(
            context: context,
            toolName: "open_order_admin@example.com",
            status: .failure,
            errorKind: .validationError,
            durationMs: nil
        )

        // When the canary inspects it
        let result = Self.checkEvent(adversarial)

        // Then the leak is reported, not silently allowed
        #expect(!result.isAllowed)
    }

    @Test
    func test_canary_when_event_carries_unbounded_string_then_reports_leak() {
        // Given a context carrying a long opaque blob past the 64-char bound
        let unboundedContext = AssistantTelemetryContext(
            conversationID: String(repeating: "a", count: 200),
            requestID: "22222222-2222-4222-8222-222222222222",
            messageID: "33333333-3333-4333-8333-333333333333"
        )

        // When the canary inspects it
        let result = Self.checkEvent(.conversationStarted(context: unboundedContext))

        // Then it surfaces the leak
        #expect(!result.isAllowed)
    }

    @Test
    func test_canary_when_value_carries_denylisted_token_then_reports_leak() {
        // Given a tool name that smuggled through a denylisted token
        let leaky: AssistantTelemetryEvent = .toolCallCompleted(
            context: context,
            toolName: "orders_summary_text",
            status: .success,
            errorKind: nil,
            durationMs: 0
        )

        // When the canary inspects it
        let result = Self.checkEvent(leaky)

        // Then it surfaces the leak
        #expect(!result.isAllowed)
    }

    /// Recursively walks an enum case (and the structs nested inside it) and returns every string
    /// leaf, so adding a new String associated value to any case is automatically covered without
    /// having to update a hand-maintained switch.
    private static func collectStrings(from value: Any) -> [String] {
        let mirror = Mirror(reflecting: value)
        if mirror.children.isEmpty {
            if let string = value as? String { return [string] }
            return []
        }
        var out: [String] = []
        for child in mirror.children {
            out.append(contentsOf: collectStrings(from: child.value))
        }
        return out
    }

    private static func checkEvent(_ event: AssistantTelemetryEvent) -> Verdict {
        let strings = collectStrings(from: event)
        for value in strings {
            if value.count > 64 {
                return .failed("string value over 64 chars: \(value.prefix(80))...")
            }
            if hasContentLeak(value) {
                return .failed("value matches content-leak regex: \(value)")
            }
            if let hit = denylistMatch(in: value) {
                return .failed("value contains denylisted token `\(hit)`: \(value)")
            }
            if !isAllowedShape(value) {
                return .failed("value does not match an allowed shape: \(value)")
            }
        }
        return .allowed
    }

    private static func denylistMatch(in value: String) -> String? {
        let lowered = value.lowercased()
        for token in denylist where lowered.contains(token) {
            return token
        }
        return nil
    }

    /// Plan requires every collected string to be a UUID, a known constant, a bounded-enum raw value,
    /// a canonical snake_case identifier, or empty. Anything else fails the canary.
    private static func isAllowedShape(_ value: String) -> Bool {
        if value.isEmpty { return true }
        if knownConstants.contains(value) { return true }
        if matches(uuidRegex, value) { return true }
        if matches(canonicalIdentifierRegex, value) { return true }
        return false
    }

    private static func matches(_ regex: NSRegularExpression, _ value: String) -> Bool {
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, options: [], range: range) != nil
    }

    private static func hasContentLeak(_ value: String) -> Bool {
        if value.isEmpty { return false }
        let range = NSRange(value.startIndex..., in: value)
        return contentLeakRegex.firstMatch(in: value, options: [], range: range) != nil
    }

    private enum Verdict {
        case allowed
        case failed(String)

        var isAllowed: Bool {
            if case .allowed = self { return true }
            return false
        }

        var reason: String? {
            if case .failed(let reason) = self { return reason }
            return nil
        }
    }
}
