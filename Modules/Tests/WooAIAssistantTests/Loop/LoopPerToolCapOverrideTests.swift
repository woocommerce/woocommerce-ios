import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopPerToolCapOverrideTests {

    @Test
    func test_dispatch_when_model_calls_products_update_twice_then_second_call_rejected_with_cap_message() async throws {
        // Given two products_update calls split across consecutive assistant turns. The cap-1
        // override fires across batches even when the first call already succeeded.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}]}"#)
        )
        let secondCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"B"}]}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(secondCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(1)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A then B") {}

        // Then
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        let secondToolMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_2" }
        let content = try #require(secondToolMessage?.content)
        #expect(content.contains("per_tool_cap_exceeded"))
        #expect(content.contains("\"cap\":1"))
        #expect(content.contains("include them all in one call"))
        #expect(content.contains("unless the previous call failed"))
    }

    @Test
    func test_dispatch_when_first_products_update_call_failed_then_second_call_allowed() async throws {
        // Given a write tool whose first invocation fails, then a retry in a follow-up assistant turn.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}]}"#)
        )
        let retryCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}],"retry":true}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(retryCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        // Failed result lets retry pass the cap; otherwise the second call would be rejected.
        await registry.setResult(for: "products_update",
                                 result: .failed(.init(toolName: "products_update",
                                                       kind: .upstreamFailure,
                                                       reason: "Network blip.")))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Retry update for A") {}

        // Then
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 2)

        let capturedRequests = await chat.capturedRequests
        let capRejection = capturedRequests
            .flatMap { $0.messages }
            .first { ($0.content ?? "").contains("per_tool_cap_exceeded") }
        #expect(capRejection == nil)
    }

    @Test
    func test_per_tool_cap_override_does_not_affect_other_tools() async throws {
        // Given a non-overridden tool fanned out four times; default cap is 4 so all succeed.
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        let scripted: [[ChatStreamEvent]] = (0..<4).map { i in
            let call = OpenAIChat.ToolCall(
                id: "call_\(i)",
                function: .init(name: "orders_list", arguments: #"{"page":\#(i + 1)}"#)
            )
            return [.toolCall(call), .completed(.toolCalls)]
        }
        await chat.setScriptedTurns(scripted + [[.textDelta("Done."), .completed(.stop)]])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   maxIterations: 6)

        // When
        for try await _ in orchestrator.run(prompt: "Walk all pages") {}

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 4)

        let capturedRequests = await chat.capturedRequests
        let anyCapRejection = capturedRequests
            .flatMap { $0.messages }
            .contains { ($0.content ?? "").contains("per_tool_cap_exceeded") }
        #expect(!anyCapRejection)
    }
}
