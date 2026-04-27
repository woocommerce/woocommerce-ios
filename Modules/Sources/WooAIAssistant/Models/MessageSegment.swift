import Foundation

/// Outer key is the row id from the underlying tool result, inner is a
/// flat string-keyed bag of overrides applied to that row.
public typealias CardRenderExtras = [String: [String: String]]

/// A single assistant turn can interleave text, tool activity, rich cards,
/// and confirmation prompts; segments are the unit each can mutate
/// independently as events stream in.
public enum MessageSegment: Identifiable, Equatable, Sendable {
    case text(id: UUID, content: String)

    /// `status` mutates in place so the same `id` survives the transition
    /// from `.running` through `.completed`/`.failed`.
    case toolCall(id: UUID,
                  toolCallID: String,
                  toolName: String,
                  argumentsPreview: String?,
                  status: ToolCallStatus)

    /// Kept in the transcript so a later `cardRender` segment can resolve
    /// its payload locally instead of holding a reference into the stream.
    case toolResult(id: UUID,
                    toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON)

    /// Snapshots the payload and extras at render time so the renderer
    /// stays self-contained even if the source `toolResult` is later
    /// replaced or the message is replayed from persistence.
    case cardRender(id: UUID,
                    toolCallID: String,
                    toolName: String,
                    payload: AnyCodableJSON,
                    extras: CardRenderExtras?)

    /// Status mutates in place so the same `id` survives the transition
    /// from `.pending` to `.confirmed` or `.cancelled`.
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
