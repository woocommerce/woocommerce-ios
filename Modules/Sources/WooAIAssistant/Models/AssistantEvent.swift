import Foundation

/// Backends translate their wire protocols into these cases so the UI
/// consumes one stream regardless of transport.
public enum AssistantEvent: Equatable, Sendable {
    /// `cardRender` events resolve their payload by matching this `id`.
    case toolCallStarted(id: String, name: String, argumentsJSON: String?)

    case toolCallCompleted(id: String, name: String, resultJSON: String?)

    /// `cardRender` events resolve the payload they should render by
    /// matching this `toolCallID`.
    case toolResult(toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON)

    /// `show_cards` selected a prior tool result for rich rendering.
    case cardRender(toolCallID: String)

    /// Safety policy pauses the loop until the user resolves this proposal.
    case confirmationRequired(proposal: ToolProposal)

    case confirmationResolved(proposalID: UUID, approved: Bool)

    /// Streaming backends emit several; non-streaming backends emit one
    /// with the whole reply.
    case textChunk(String)

    /// `routeConfidence` is in the 0.0...1.0 range when present.
    case completed(routeConfidence: Double?)

    case failed(AssistantError)
}

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

/// `kind` is non-optional so the UI can always branch on a typed failure
/// state (e.g. `outcomeUnknown` for in-flight write cancellations). Use
/// `.unknown` when the cause is genuinely unidentified.
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
