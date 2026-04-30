import Foundation
import Observation

/// Observable source of truth for one chat conversation.
@MainActor
@Observable
public final class AssistantConversation {

    public enum StreamingState: Equatable, Sendable {
        case idle
        case sending
        case streaming
        case failed(String)
        case outcomeUnknown(String)
    }

    public private(set) var messages: [ChatMessage] = []
    public private(set) var streamingState: StreamingState = .idle
    public internal(set) var session: AssistantSession?

    private(set) var outcomeUnknownObserved: Bool = false

    public init() {}

    init(seededMessages: [ChatMessage]) {
        self.messages = seededMessages
    }

    func appendUserMessage(_ text: String) -> ChatMessage {
        let message = ChatMessage(role: .user,
                                  segments: [.text(id: UUID(), content: text)])
        messages.append(message)
        return message
    }

    func beginAssistantMessage() -> ChatMessage.ID {
        let message = ChatMessage(role: .assistant, isStreaming: true)
        messages.append(message)
        outcomeUnknownObserved = false
        return message.id
    }

    func apply(_ event: AssistantEvent, to assistantMessageID: ChatMessage.ID) {
        guard let index = messages.firstIndex(where: { $0.id == assistantMessageID }) else { return }
        switch event {
        case .textChunk(let chunk):
            messages[index].updateText(appending: chunk)
        case .toolCallStarted(let id, let name, let args):
            messages[index].append(.toolCall(id: UUID(),
                                             toolCallID: id,
                                             toolName: name,
                                             argumentsPreview: args,
                                             status: .running))
        case .toolCallCompleted(let id, _, let resultJSON):
            messages[index].updateToolCall(id: id,
                                           to: .completed(summary: resultSummary(from: resultJSON)))
        case .toolResult(let toolCallID, let toolName, let payload):
            messages[index].append(.toolResult(id: UUID(),
                                               toolCallID: toolCallID,
                                               toolName: toolName,
                                               payload: payload))
        case .cardRender(let toolCallID):
            // Silently drop renders for unknown tool call IDs.
            if let match = Self.firstMatchingToolResult(in: messages[index].segments,
                                                       toolCallID: toolCallID) {
                messages[index].append(.cardRender(id: UUID(),
                                                   toolCallID: toolCallID,
                                                   toolName: match.toolName,
                                                   payload: match.payload))
            }
        case .confirmationRequired(let proposal):
            messages[index].append(.confirmation(id: UUID(),
                                                 proposalID: proposal.id,
                                                 toolName: proposal.toolName,
                                                 preview: proposal.preview,
                                                 status: .pending))
        case .confirmationResolved(let proposalID, let approved):
            messages[index].updateConfirmation(proposalID: proposalID,
                                               to: approved ? .confirmed : .cancelled)
        case .completed:
            messages[index].markCompleted()
        case .failed(let error):
            switch error.kind {
            case .outcomeUnknown:
                // Per-call event; rest of turn keeps the distinct surface.
                outcomeUnknownObserved = true
                streamingState = .outcomeUnknown(error.message)
            default:
                messages[index].markCompleted()
                streamingState = .failed(error.message)
            }
        }
    }

    func setStreaming(_ state: StreamingState) {
        if outcomeUnknownObserved, case .streaming = state { return }
        if outcomeUnknownObserved, case .idle = state { return }
        streamingState = state
    }

    func replaceSession(_ newSession: AssistantSession) {
        session = newSession
    }

    private func resultSummary(from json: String?) -> String? {
        guard let json else { return nil }
        let limit = 120
        if json.count <= limit { return json }
        return String(json.prefix(limit)) + "..."
    }

    private static func firstMatchingToolResult(in segments: [MessageSegment],
                                                toolCallID: String) -> (toolName: String,
                                                                        payload: AnyCodableJSON)? {
        for segment in segments {
            if case .toolResult(_, let id, let name, let payload) = segment, id == toolCallID {
                return (name, payload)
            }
        }
        return nil
    }
}
