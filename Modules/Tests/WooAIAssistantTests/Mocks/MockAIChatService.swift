import Foundation
@testable import WooAIAssistant

actor MockAIChatService: AIChatService {
    var scriptedTurns: [[ChatStreamEvent]] = []
    var streamError: Error?
    private(set) var capturedRequests: [(messages: [OpenAIChat.Message],
                                          tools: [OpenAIChat.ToolDefinition]?)] = []

    func setScriptedTurns(_ turns: [[ChatStreamEvent]]) {
        scriptedTurns = turns
    }

    func setStreamError(_ error: Error?) {
        streamError = error
    }

    nonisolated func streamTurn(messages: [OpenAIChat.Message],
                                tools: [OpenAIChat.ToolDefinition]?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let events = await self.consumeNextTurn(messages: messages,
                                                        tools: tools)
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
                                 tools: [OpenAIChat.ToolDefinition]?) -> (events: [ChatStreamEvent], error: Error?) {
        capturedRequests.append((messages, tools))
        let events: [ChatStreamEvent]
        if scriptedTurns.isEmpty {
            events = [.completed(nil)]
        } else {
            events = scriptedTurns.removeFirst()
        }
        return (events, streamError)
    }
}
