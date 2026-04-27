import Foundation

/// One turn in the assistant transcript. Holds an ordered list of segments
/// that the controller mutates as text streams in, tools dispatch, and
/// confirmations resolve.
public struct ChatMessage: Identifiable, Equatable, Sendable {
    public enum Role: Sendable, Equatable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public private(set) var segments: [MessageSegment]
    public let createdAt: Date
    public private(set) var isStreaming: Bool

    public init(id: UUID = UUID(),
                role: Role,
                segments: [MessageSegment] = [],
                createdAt: Date = Date(),
                isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.segments = segments
        self.createdAt = createdAt
        self.isStreaming = isStreaming
    }

    public mutating func append(_ segment: MessageSegment) {
        segments.append(segment)
    }

    /// Append `chunk` to the trailing `.text` segment, or start a new one
    /// when the latest segment is a non-text type.
    public mutating func updateText(appending chunk: String) {
        if case .text(let id, let current) = segments.last {
            segments[segments.count - 1] = .text(id: id, content: current + chunk)
        } else {
            segments.append(.text(id: UUID(), content: chunk))
        }
    }

    /// Update the status (and optional summary) of an in-flight `.toolCall`
    /// segment matched by `toolCallID`. No-op when the segment is missing.
    public mutating func updateToolCall(id toolCallID: String,
                                        to status: ToolCallStatus,
                                        summary: String? = nil) {
        for index in segments.indices {
            if case .toolCall(let segmentID, let existingID, let name, let args, _) = segments[index],
               existingID == toolCallID {
                segments[index] = .toolCall(id: segmentID,
                                            toolCallID: existingID,
                                            toolName: name,
                                            argumentsPreview: args,
                                            status: status)
                return
            }
        }
    }

    /// Resolve a pending `.confirmation` segment matched by `proposalID`.
    /// No-op when the segment is missing.
    public mutating func updateConfirmation(proposalID: UUID,
                                            to status: ConfirmationStatus) {
        for index in segments.indices {
            if case .confirmation(let id, let pid, let name, let preview, _) = segments[index],
               pid == proposalID {
                segments[index] = .confirmation(id: id,
                                                proposalID: pid,
                                                toolName: name,
                                                preview: preview,
                                                status: status)
                return
            }
        }
    }

    public mutating func markCompleted() {
        isStreaming = false
    }
}
