import Foundation

public protocol HistoryBudgeter: Sendable {
    func budget(systemPrompt: OpenAIChat.Message?,
                priorMessages: [OpenAIChat.Message],
                currentUserPrompt: String) -> [OpenAIChat.Message]
}

public struct SlidingWindowHistoryBudgeter: HistoryBudgeter {

    private let windowSize: Int

    public init(windowSize: Int = AssistantConfiguration.historyWindowSize) {
        self.windowSize = max(0, windowSize)
    }

    public func budget(systemPrompt: OpenAIChat.Message?,
                       priorMessages: [OpenAIChat.Message],
                       currentUserPrompt: String) -> [OpenAIChat.Message] {
        var output: [OpenAIChat.Message] = []
        if let systemPrompt {
            output.append(systemPrompt)
        }
        guard windowSize > 0 else {
            return output
        }
        var window = Array(priorMessages.suffix(windowSize))
        // Drop leading orphan tool messages: OpenAI rejects a `.tool` message
        // without a preceding `.assistant` message carrying matching tool_calls.
        while let first = window.first, first.role == .tool {
            window.removeFirst()
        }
        // Second pass: an assistant with tool_calls whose IDs are not all
        // matched by later .tool messages in the window is itself an orphan.
        if let first = window.first,
           first.role == .assistant,
           let calls = first.toolCalls, calls.isEmpty == false {
            let laterToolIDs = Set(window.dropFirst()
                .filter { $0.role == .tool }
                .compactMap { $0.toolCallID })
            let allMatched = calls.allSatisfy { laterToolIDs.contains($0.id) }
            if allMatched == false {
                window.removeFirst()
            }
        }
        output.append(contentsOf: window)
        return output
    }
}
