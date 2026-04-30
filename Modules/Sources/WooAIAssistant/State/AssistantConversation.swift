import Foundation
import Observation

/// Observable source of truth for one chat conversation. Holds the ordered message
/// list, a backend-opaque session handle, and the streaming state the input bar
/// uses to swap between send and stop affordances.
@MainActor
@Observable
public final class AssistantConversation {

    public enum StreamingState: Equatable, Sendable {
        case idle
        case sending
        case streaming
        case failed(String)
        /// Distinct from `.failed` so the UI can render a "I started this but
        /// couldn't confirm it finished" message - the merchant should check
        /// the native UI rather than treat the turn as a flat error.
        case outcomeUnknown(String)
    }

    public private(set) var messages: [ChatMessage] = []
    public private(set) var streamingState: StreamingState = .idle
    public internal(set) var session: AssistantSession?

    public init() {}

    init(seededMessages: [ChatMessage]) {
        self.messages = seededMessages
    }

    // MARK: - Mutations

    func appendUserMessage(_ text: String) -> ChatMessage {
        let message = ChatMessage(role: .user,
                                  segments: [.text(id: UUID(), content: text)])
        messages.append(message)
        return message
    }

    func beginAssistantMessage() -> ChatMessage.ID {
        let message = ChatMessage(role: .assistant, isStreaming: true)
        messages.append(message)
        return message.id
    }

    /// Routes one orchestrator event into the targeted assistant message. The
    /// segment identity in `ChatMessage` is preserved across mutations so the
    /// SwiftUI list keeps stable rows under streaming updates.
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
            // Drop silently when no matching `toolResult` exists - the model
            // referenced an id we never saw, the text answer still renders,
            // and a missing card is a softer failure than a crash.
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
            messages[index].markCompleted()
            switch error.kind {
            case .outcomeUnknown:
                streamingState = .outcomeUnknown(error.message)
            default:
                streamingState = .failed(error.message)
            }
        }
    }

    func setStreaming(_ state: StreamingState) {
        streamingState = state
    }

    func replaceSession(_ newSession: AssistantSession) {
        session = newSession
    }

    // MARK: - Helpers

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
