import Foundation

/// Transport seam the orchestrator depends on. Conformers reassemble `OpenAIChat.ToolCallDelta`
/// fragments into complete `ToolCall` values before emission; the orchestrator never sees deltas.
public protocol AIChatService: Sendable {
    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?,
                    toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error>
}

extension AIChatService {
    public func streamTurn(messages: [OpenAIChat.Message],
                           tools: [OpenAIChat.ToolDefinition]?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        streamTurn(messages: messages, tools: tools, toolChoice: nil)
    }
}

public enum ChatStreamEvent: Sendable, Equatable {
    case textDelta(String)
    case toolCall(OpenAIChat.ToolCall)
    case completed(OpenAIChat.FinishReason?)
}
