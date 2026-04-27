import Foundation

/// Per-row card overrides keyed by row id, then key/value strings.
public typealias CardRenderExtras = [String: [String: String]]

/// A piece of content inside a `ChatMessage`. Messages hold an ordered list
/// of these so a single assistant turn can interleave text, tool activity,
/// rich cards, and confirmation prompts.
public enum MessageSegment: Identifiable, Equatable, Sendable {
    /// Assistant-authored prose.
    case text(id: UUID, content: String)

    /// A tool the assistant is invoking. `status` evolves in place as the
    /// dispatch progresses.
    case toolCall(id: UUID,
                  toolCallID: String,
                  toolName: String,
                  argumentsPreview: String?,
                  status: ToolCallStatus)

    /// Structured result of a tool call kept in the transcript so the UI
    /// can resolve a card-render reference back to its underlying payload.
    case toolResult(id: UUID,
                    toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON)

    /// A card requested by a `show_cards` tool call. Captures the snapshotted
    /// payload plus any per-row extras so the renderer is self-contained.
    case cardRender(id: UUID,
                    toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON,
                    extras: CardRenderExtras?)

    /// A pending user confirmation for a destructive tool call. The status
    /// transitions from `.pending` to `.confirmed` or `.cancelled` once the
    /// user resolves the prompt.
    case confirmation(id: UUID,
                      proposalID: UUID,
                      toolName: String,
                      preview: String,
                      status: ConfirmationStatus)

    public var id: UUID {
        switch self {
        case .text(let id, _),
             .toolCall(let id, _, _, _, _),
             .toolResult(let id, _, _, _),
             .cardRender(let id, _, _, _, _),
             .confirmation(let id, _, _, _, _):
            return id
        }
    }
}

public enum ToolCallStatus: Equatable, Sendable {
    case running
    case completed(summary: String?)
    case failed(message: String)
}

public enum ConfirmationStatus: Equatable, Sendable {
    case pending
    case confirmed
    case cancelled
}
