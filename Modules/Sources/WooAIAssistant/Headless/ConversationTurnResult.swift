import Foundation

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
