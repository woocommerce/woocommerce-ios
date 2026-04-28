import Foundation

/// Transport-level abstraction the orchestrator depends on for chat completions.
///
/// Why a dedicated event type rather than `AssistantEvent`: the chat service is purely a wire-level
/// seam. It does not understand confirmation, cards, dedupe, or loop concerns. The orchestrator
/// translates `ChatStreamEvent` into `AssistantEvent` and drives the loop on top.
///
// internal because OpenAIChat types are not yet exposed to the host app.
protocol AIChatService: Sendable {
    /// Stream one chat completion. The orchestrator drains the stream
    /// to a `.completed` event, accumulating text deltas and tool
    /// calls in order. `toolChoice` is optional (defaults to nil) so
    /// most callers can stay on the model's automatic behavior.
    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?,
                    toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error>
}

extension AIChatService {
    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        streamTurn(messages: messages, tools: tools, toolChoice: nil)
    }
}

/// Wire-level events the chat service emits while a turn streams.
/// Tool-call deltas must be reassembled by the transport before
/// surfacing as `.toolCall` so the orchestrator only sees complete
/// calls with valid arguments JSON.
enum ChatStreamEvent: Sendable, Equatable {
    case textDelta(String)
    case toolCall(OpenAIChat.ToolCall)
    case completed(OpenAIChat.FinishReason?)
}
