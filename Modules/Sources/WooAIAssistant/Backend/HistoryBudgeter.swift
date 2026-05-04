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
        while let first = window.first {
            if first.role == .tool {
                window.removeFirst()
                continue
            }
            if first.hasUnmatchedToolCalls(in: window.dropFirst()) {
                window.removeFirst()
                continue
            }
            break
        }
        output.append(contentsOf: window)
        return output
    }
}

private extension OpenAIChat.Message {
    func hasUnmatchedToolCalls(in laterMessages: ArraySlice<OpenAIChat.Message>) -> Bool {
        guard role == .assistant,
              let calls = toolCalls,
              calls.isEmpty == false else {
            return false
        }
        let laterToolIDs = Set(laterMessages
            .filter { $0.role == .tool }
            .compactMap { $0.toolCallID })
        return calls.contains { laterToolIDs.contains($0.id) == false }
    }
}
