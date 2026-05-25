import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopDedupeTests {

    @Test
    func test_dedupe_when_second_identical_call_then_replays_cached_payload_with_soft_hint() async throws {
        // Given
        let listTool = AITool(name: "products_list",
                              description: "List products",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_list", arguments: #"{"per_page":5}"#)
        )
        let identicalCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_list", arguments: #"{"per_page":5}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(identicalCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "products_list",
                                 result: .success(.init(toolName: "products_list",
                                                        structured: .object(["count": .int(2)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Show me products") {
            events.append(event)
        }

        // Then
        let invocations = await registry.invocationCount(for: "products_list")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 3)
        let thirdRequest = capturedRequests[2]
        let dupeToolMessage = thirdRequest.messages.last { $0.role == .tool && $0.toolCallID == "call_2" }
        let content = try #require(dupeToolMessage?.content)
        #expect(content.contains("cached_result_reused"))
        #expect(content.contains("\"prior_identical_calls_this_turn\":1"))
        #expect(!content.contains("must_respond_now\":true"))
    }

    @Test
    func test_dedupe_when_third_identical_call_then_replays_with_must_respond_now_marker() async throws {
        // Given
        let listTool = AITool(name: "products_list",
                              description: "List products",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_list", arguments: #"{"per_page":5}"#)
        )
        let secondCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_list", arguments: #"{"per_page":5}"#)
        )
        let thirdCall = OpenAIChat.ToolCall(
            id: "call_3",
            function: .init(name: "products_list", arguments: #"{"per_page":5}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(secondCall), .completed(.toolCalls)],
            [.toolCall(thirdCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "products_list",
                                 result: .success(.init(toolName: "products_list",
                                                        structured: .object(["count": .int(2)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Show me products") {
            events.append(event)
        }

        // Then
        let invocations = await registry.invocationCount(for: "products_list")
        #expect(invocations == 1)
        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 4)
        let fourthRequest = capturedRequests[3]
        let escalatedToolMessage = fourthRequest.messages.last { $0.role == .tool && $0.toolCallID == "call_3" }
        let content = try #require(escalatedToolMessage?.content)
        #expect(content.contains("cached_result_reused"))
        #expect(content.contains("must_respond_now\":true"))
        #expect(content.contains("stop_reason"))
        #expect(content.contains("duplicate_tool_call"))
    }

    @Test
    func test_dedupe_when_three_identical_calls_in_one_batch_then_third_escalates_must_respond_now() async throws {
        // Given an assistant message that fans out the same call three times in one batch.
        // Across-turn duplication is already covered above; the same-batch path used to
        // hardcode `priorSeen: 1` for every secondary, so `[A, A, A]` never escalated.
        let listTool = AITool(name: "products_list",
                              description: "List products",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstCall = OpenAIChat.ToolCall(id: "call_1",
                                            function: .init(name: "products_list", arguments: #"{"per_page":5}"#))
        let secondCall = OpenAIChat.ToolCall(id: "call_2",
                                             function: .init(name: "products_list", arguments: #"{"per_page":5}"#))
        let thirdCall = OpenAIChat.ToolCall(id: "call_3",
                                            function: .init(name: "products_list", arguments: #"{"per_page":5}"#))
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .toolCall(secondCall), .toolCall(thirdCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "products_list",
                                 result: .success(.init(toolName: "products_list",
                                                        structured: .object(["count": .int(2)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Show me products") {}

        // Then only the primary actually dispatches; the second is a soft replay; the third escalates.
        let invocations = await registry.invocationCount(for: "products_list")
        #expect(invocations == 1)
        let capturedRequests = await chat.capturedRequests
        let secondTurn = try #require(capturedRequests.dropFirst().first)
        let secondaryMessage = try #require(secondTurn.messages.first { $0.role == .tool && $0.toolCallID == "call_2" })
        let tertiaryMessage = try #require(secondTurn.messages.first { $0.role == .tool && $0.toolCallID == "call_3" })
        let secondaryContent = try #require(secondaryMessage.content)
        let tertiaryContent = try #require(tertiaryMessage.content)
        #expect(secondaryContent.contains("cached_result_reused"))
        #expect(!secondaryContent.contains("must_respond_now\":true"))
        #expect(tertiaryContent.contains("cached_result_reused"))
        #expect(tertiaryContent.contains("must_respond_now\":true"))
    }
}
