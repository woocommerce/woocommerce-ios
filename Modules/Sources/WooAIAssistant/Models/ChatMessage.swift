import Foundation

/// One transcript turn. Segments are mutated in place as text streams in,
/// tools dispatch, and confirmations resolve, so views observing the
/// message see the message identity stay constant across updates.
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

    /// Coalesces consecutive text chunks into a single segment so the
    /// transcript renders as one paragraph instead of fragmenting per chunk.
    public mutating func updateText(appending chunk: String) {
        if case .text(let id, let current) = segments.last {
            segments[segments.count - 1] = .text(id: id, content: current + chunk)
        } else {
            segments.append(.text(id: UUID(), content: chunk))
        }
    }

    /// No-op when the segment is missing so out-of-order events from a
    /// reconnected stream can't crash the controller.
    public mutating func updateToolCall(id toolCallID: String,
                                        to status: ToolCallStatus) {
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

    /// No-op when the segment is missing so a late confirmation event for
    /// a discarded message can't crash the controller.
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
        trimTrailingWhitespaceFromTextSegments()
    }

    private mutating func trimTrailingWhitespaceFromTextSegments() {
        for index in segments.indices {
            if case .text(let id, let content) = segments[index] {
                let trimmed = content.trimmedTrailingWhitespace()
                if trimmed != content {
                    segments[index] = .text(id: id, content: trimmed)
                }
            }
        }
    }

    public mutating func cancelPendingConfirmations() {
        for index in segments.indices {
            if case .confirmation(let id, let pid, let name, let preview, .pending) = segments[index] {
                segments[index] = .confirmation(id: id,
                                                proposalID: pid,
                                                toolName: name,
                                                preview: preview,
                                                status: .cancelled)
            }
        }
    }

    public var hasPendingConfirmation: Bool {
        for segment in segments {
            if case .confirmation(_, _, _, _, .pending) = segment {
                return true
            }
        }
        return false
    }
}

public extension Array where Element == ChatMessage {
    /// True when any assistant message is awaiting a merchant decision on a
    /// confirmation card. The agentic loop is suspended in this state, so the
    /// chat surface should not show "assistant is thinking" affordances.
    var hasPendingConfirmation: Bool {
        contains { $0.hasPendingConfirmation }
    }
}

private extension String {
    func trimmedTrailingWhitespace() -> String {
        var result = self
        while let last = result.last, last.isWhitespace || last.isNewline {
            result.removeLast()
        }
        return result
    }
}
