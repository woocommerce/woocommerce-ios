import Foundation
@testable import WooAIAssistant

/// Test double for `AIChatService`. Each call to `streamTurn` consumes
/// the next entry from `scriptedTurns` and yields it as an async
/// stream. Captured requests let the test inspect the message
/// transcript the orchestrator built up.
final class MockAIChatService: AIChatService, @unchecked Sendable {
    var scriptedTurns: [[ChatStreamEvent]] = []
    var streamError: Error?
    private(set) var capturedRequests: [(messages: [OpenAIChat.Message],
                                          tools: [OpenAIChat.ToolDefinition]?,
                                          toolChoice: OpenAIChat.ToolChoice?)] = []

    func streamTurn(messages: [OpenAIChat.Message],
                    tools: [OpenAIChat.ToolDefinition]?,
                    toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        capturedRequests.append((messages, tools, toolChoice))
        let events: [ChatStreamEvent]
        if scriptedTurns.isEmpty {
            events = [.completed(nil)]
        } else {
            events = scriptedTurns.removeFirst()
        }
        let error = streamError
        return AsyncThrowingStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}
