import Foundation
@testable import WooAIAssistant

/// Test double for `AIChatService`. Each call to `streamTurn` consumes
/// the next entry from `scriptedTurns` and yields it as an async
/// stream. Captured requests let the test inspect the message
/// transcript the orchestrator built up.
actor MockAIChatService: AIChatService {
    var scriptedTurns: [[ChatStreamEvent]] = []
    var streamError: Error?
    private(set) var capturedRequests: [(messages: [OpenAIChat.Message],
                                          tools: [OpenAIChat.ToolDefinition]?,
                                          toolChoice: OpenAIChat.ToolChoice?)] = []

    func setScriptedTurns(_ turns: [[ChatStreamEvent]]) {
        scriptedTurns = turns
    }

    func setStreamError(_ error: Error?) {
        streamError = error
    }

    nonisolated func streamTurn(messages: [OpenAIChat.Message],
                                tools: [OpenAIChat.ToolDefinition]?,
                                toolChoice: OpenAIChat.ToolChoice?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let events = await self.consumeNextTurn(messages: messages,
                                                        tools: tools,
                                                        toolChoice: toolChoice)
                for event in events.events {
                    continuation.yield(event)
                }
                if let error = events.error {
                    continuation.finish(throwing: error)
                } else {
                    continuation.finish()
                }
            }
        }
    }

    private func consumeNextTurn(messages: [OpenAIChat.Message],
                                 tools: [OpenAIChat.ToolDefinition]?,
                                 toolChoice: OpenAIChat.ToolChoice?) -> (events: [ChatStreamEvent], error: Error?) {
        capturedRequests.append((messages, tools, toolChoice))
        let events: [ChatStreamEvent]
        if scriptedTurns.isEmpty {
            events = [.completed(nil)]
        } else {
            events = scriptedTurns.removeFirst()
        }
        return (events, streamError)
    }
}
