import Foundation
import Testing
@testable import WooAIAssistant

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
}
