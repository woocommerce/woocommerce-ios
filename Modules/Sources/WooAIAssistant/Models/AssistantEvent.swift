import Foundation

/// Backend-agnostic event emitted while the assistant is processing a turn.
///
/// Concrete backends translate their wire protocols into these cases so the
/// UI consumes one stream regardless of transport.
public enum AssistantEvent: Equatable, Sendable {
    /// The backend started a named tool call.
    case toolCallStarted(id: String, name: String, argumentsJSON: String?)

    /// A previously started tool call completed with a raw JSON payload.
    case toolCallCompleted(id: String, name: String, resultJSON: String?)

    /// Structured result of a tool call. Cached by `toolCallID` so a later
    /// `cardRender` can resolve the payload it should render.
    case toolResult(toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON)

    /// `show_cards` selected a prior tool result for rich rendering, with
    /// optional per-row extras drawn beneath the card layout.
    case cardRender(toolCallID: String,
                    extras: CardRenderExtras?)

    /// Safety policy paused the loop pending user approval. The UI renders
    /// a confirmation card built from the proposal.
    case confirmationRequired(proposal: ToolProposal)

    /// A previously emitted confirmation got a decision.
    case confirmationResolved(proposalID: UUID, approved: Bool)

    /// A chunk of assistant-authored text. Streaming backends emit several;
    /// non-streaming backends emit one with the whole reply.
    case textChunk(String)

    /// The turn finished successfully. `routeConfidence` is optional
    /// metadata some backends expose in the 0.0...1.0 range.
    case completed(routeConfidence: Double?)

    /// The turn failed. `error` is user-visible.
    case failed(AssistantError)
}

/// Pending user-approval payload that pauses the loop until the user
/// confirms or cancels.
public struct ToolProposal: Equatable, Sendable {
    public let id: UUID
    public let toolName: String
    public let toolCallID: String
    public let preview: String

    public init(id: UUID = UUID(),
                toolName: String,
                toolCallID: String,
                preview: String) {
        self.id = id
        self.toolName = toolName
        self.toolCallID = toolCallID
        self.preview = preview
    }
}

/// User-visible failure carried by `AssistantEvent.failed`. `kind` lets the
/// UI distinguish typed states (e.g. `outcome_unknown` for in-flight write
/// cancellations) from generic failures. Use `.unknown` when the cause is
/// genuinely unidentified.
public struct AssistantError: Error, Equatable, Sendable {
    public let kind: AssistantErrorKind
    public let code: String?
    public let message: String

    public init(kind: AssistantErrorKind,
                code: String? = nil,
                message: String) {
        self.kind = kind
        self.code = code
        self.message = message
    }
}
