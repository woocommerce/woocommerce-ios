import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AgenticChatBackendHistoryBudgeterTests {

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    @Test
    func test_send_when_transcript_exceeds_window_then_orchestrator_receives_only_budgeted_messages()
    async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("a1"), .completed(.stop)],
            [.textDelta("a2"), .completed(.stop)],
            [.textDelta("a3"), .completed(.stop)],
            [.textDelta("a4"), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPrompt: nil,
                                         historyBudgeter: SlidingWindowHistoryBudgeter(windowSize: 2))

        // When
        for prompt in ["t1", "t2", "t3", "t4"] {
            let stream = backend.send(turn: .init(prompt: prompt),
                                      context: defaultContext,
                                      session: nil)
            for try await _ in stream {}
        }

        // Then
        let captured = await chat.capturedRequests
        let lastMessages = try #require(captured.last?.messages)
        let priorOnly = lastMessages.dropLast()
        #expect(priorOnly.count == 2)
        let priorContents = priorOnly.compactMap(\.content)
        #expect(priorContents == ["t3", "a3"])
        #expect(lastMessages.last?.role == .user)
        #expect(lastMessages.last?.content == "t4")
    }

    @Test
    func test_send_when_transcript_exceeds_window_then_TranscriptStore_retains_full_history()
    async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("a1"), .completed(.stop)],
            [.textDelta("a2"), .completed(.stop)],
            [.textDelta("a3"), .completed(.stop)],
            [.textDelta("a4"), .completed(.stop)],
            [.textDelta("a5"), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPrompt: nil,
                                         historyBudgeter: PassthroughHistoryBudgeter())

        // When
        for prompt in ["t1", "t2", "t3", "t4", "t5"] {
            let stream = backend.send(turn: .init(prompt: prompt),
                                      context: defaultContext,
                                      session: nil)
            for try await _ in stream {}
        }

        // Then
        let captured = await chat.capturedRequests
        let lastMessages = try #require(captured.last?.messages)
        let lastPriorMessages = lastMessages.dropLast()
        let userContents = lastPriorMessages.filter { $0.role == .user }.compactMap(\.content)
        let assistantContents = lastPriorMessages.filter { $0.role == .assistant }.compactMap(\.content)
        #expect(userContents == ["t1", "t2", "t3", "t4"])
        #expect(assistantContents == ["a1", "a2", "a3", "a4"])
        #expect(lastMessages.last?.content == "t5")
    }

    @Test
    func test_send_when_systemPromptProvider_returns_value_then_budgeted_output_starts_with_system()
    async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("a1"), .completed(.stop)],
            [.textDelta("a2"), .completed(.stop)]
        ])
        let backend = AgenticChatBackend(chatService: chat,
                                         systemPrompt: "you are helpful",
                                         historyBudgeter: SlidingWindowHistoryBudgeter(windowSize: 1))

        // When
        for prompt in ["t1", "t2"] {
            let stream = backend.send(turn: .init(prompt: prompt),
                                      context: defaultContext,
                                      session: nil)
            for try await _ in stream {}
        }

        // Then
        let captured = await chat.capturedRequests
        let lastMessages = try #require(captured.last?.messages)
        #expect(lastMessages.first?.role == .system)
        #expect(lastMessages.first?.content == "you are helpful")
        let beforeUser = lastMessages.dropFirst().dropLast()
        #expect(beforeUser.count == 1)
        #expect(beforeUser.first?.content == "a1")
        #expect(lastMessages.last?.content == "t2")
    }
}

private struct PassthroughHistoryBudgeter: HistoryBudgeter {

    func budget(systemPrompt: OpenAIChat.Message?,
                priorMessages: [OpenAIChat.Message],
                currentUserPrompt: String) -> [OpenAIChat.Message] {
        [systemPrompt].compactMap { $0 } + priorMessages
    }
}
