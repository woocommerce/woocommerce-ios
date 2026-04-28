import Foundation

/// The transport seam the orchestrator depends on. Conforming types own SSE / streaming /
/// delta-assembly concerns; the orchestrator only sees well-formed `OpenAIChat.ToolCall` values via
/// `.toolCall(...)` events. In particular, `OpenAIChat.ToolCallDelta` fragments arriving in the raw
/// stream MUST be assembled into complete `ToolCall` values by this layer before emission. The
/// orchestrator does no delta reassembly.
// internal because OpenAIChat types are not yet exposed to the host app.
protocol AIChatService: Sendable {
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

enum ChatStreamEvent: Sendable, Equatable {
    case textDelta(String)
    case toolCall(OpenAIChat.ToolCall)
    case completed(OpenAIChat.FinishReason?)
}
