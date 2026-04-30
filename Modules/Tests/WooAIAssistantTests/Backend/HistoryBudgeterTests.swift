import Foundation
import Testing
@testable import WooAIAssistant

struct HistoryBudgeterTests {

    @Test
    func test_budget_when_transcript_empty_then_returns_only_system_prompt() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 20)
        let system = OpenAIChat.Message(role: .system, content: "you are helpful")

        // When
        let result = budgeter.budget(systemPrompt: system,
                                     priorMessages: [],
                                     currentUserPrompt: "hi")

        // Then
        #expect(result.count == 1)
        #expect(result.first?.role == .system)
        #expect(result.first?.content == "you are helpful")
    }

    @Test
    func test_budget_when_transcript_shorter_than_window_then_returns_full_transcript_with_system_prepended() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 20)
        let system = OpenAIChat.Message(role: .system, content: "sys")
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: "a1"),
            .init(role: .user, content: "u2"),
            .init(role: .assistant, content: "a2")
        ]

        // When
        let result = budgeter.budget(systemPrompt: system,
                                     priorMessages: transcript,
                                     currentUserPrompt: "u3")

        // Then
        #expect(result.map(\.role) == [.system, .user, .assistant, .user, .assistant])
        #expect(result.dropFirst().compactMap(\.content) == ["u1", "a1", "u2", "a2"])
    }

    @Test
    func test_budget_when_transcript_longer_than_window_then_returns_last_N_messages_with_system_prepended() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 3)
        let system = OpenAIChat.Message(role: .system, content: "sys")
        let transcript: [OpenAIChat.Message] = (1...5).map {
            .init(role: .user, content: "msg\($0)")
        }

        // When
        let result = budgeter.budget(systemPrompt: system,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.count == 4)
        #expect(result.first?.role == .system)
        let trailingContents = result.dropFirst().compactMap(\.content)
        #expect(trailingContents == ["msg3", "msg4", "msg5"])
    }

    @Test
    func test_budget_when_no_system_prompt_then_omits_system_message() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 5)
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: "a1")
        ]

        // When
        let result = budgeter.budget(systemPrompt: nil,
                                     priorMessages: transcript,
                                     currentUserPrompt: "u2")

        // Then
        #expect(result.contains(where: { $0.role == .system }) == false)
        #expect(result.map(\.role) == [.user, .assistant])
    }

    @Test
    func test_budget_when_window_cuts_orphan_tool_message_then_drops_leading_tool() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 2)
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: nil, toolCalls: [
                .init(id: "c1", function: .init(name: "tool", arguments: "{}"))
            ]),
            .init(role: .tool, content: "{}", toolCallID: "c1"),
            .init(role: .assistant, content: "a1")
        ]

        // When
        let result = budgeter.budget(systemPrompt: nil,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.map(\.role) == [.assistant])
        #expect(result.first?.content == "a1")
    }

    @Test
    func test_budget_when_window_cuts_assistant_with_unmatched_toolCalls_then_drops_that_assistant() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 2)
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: nil, toolCalls: [
                .init(id: "c1", function: .init(name: "tool", arguments: "{}"))
            ]),
            .init(role: .tool, content: "{}", toolCallID: "c1"),
            .init(role: .assistant, content: nil, toolCalls: [
                .init(id: "c2", function: .init(name: "tool", arguments: "{}"))
            ]),
            .init(role: .user, content: "u2")
        ]

        // When
        let result = budgeter.budget(systemPrompt: nil,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.map(\.role) == [.user])
        #expect(result.first?.content == "u2")
    }

    @Test
    func test_budget_when_window_keeps_complete_tool_pair_then_pair_preserved() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 3)
        let toolCall = OpenAIChat.ToolCall(id: "c1",
                                           function: .init(name: "tool", arguments: "{}"))
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: nil, toolCalls: [toolCall]),
            .init(role: .tool, content: "{}", toolCallID: "c1")
        ]

        // When
        let result = budgeter.budget(systemPrompt: nil,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.map(\.role) == [.user, .assistant, .tool])
        #expect(result[1].toolCalls?.map(\.id) == ["c1"])
        #expect(result[2].toolCallID == "c1")
    }

    @Test
    func test_budget_when_windowSize_zero_then_returns_only_system_prompt() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: 0)
        let system = OpenAIChat.Message(role: .system, content: "sys")
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: "a1")
        ]

        // When
        let result = budgeter.budget(systemPrompt: system,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.map(\.role) == [.system])
    }

    @Test
    func test_init_when_windowSize_negative_then_clamps_to_zero() {
        // Given
        let budgeter = SlidingWindowHistoryBudgeter(windowSize: -5)
        let transcript: [OpenAIChat.Message] = [
            .init(role: .user, content: "u1"),
            .init(role: .assistant, content: "a1")
        ]

        // When
        let result = budgeter.budget(systemPrompt: nil,
                                     priorMessages: transcript,
                                     currentUserPrompt: "next")

        // Then
        #expect(result.isEmpty)
    }
}
