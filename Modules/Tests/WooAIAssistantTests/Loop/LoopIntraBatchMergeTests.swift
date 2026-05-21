import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopIntraBatchMergeTests {

    @Test
    func test_dispatch_when_model_emits_two_products_update_in_one_batch_then_calls_merged_before_dispatch() async throws {
        // Given
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
            [.toolCall(firstCall), .toolCall(secondCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(2)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A and B") {}

        // Then
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let mergedArgs = await registry.lastArguments(for: "products_update")
        let unwrapped = try #require(mergedArgs)
        #expect(unwrapped.contains("\"target\":\"A\""))
        #expect(unwrapped.contains("\"target\":\"B\""))

        let capturedRequests = await chat.capturedRequests
        let secondaryMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_2" }
        let secondaryContent = try #require(secondaryMessage?.content)
        #expect(secondaryContent.contains("merged_into_call"))
        #expect(secondaryContent.contains("call_1"))

        let leaderMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_1" }
        let leaderContent = try #require(leaderMessage?.content)
        #expect(leaderContent.contains("\"updated\":2"))
        #expect(!leaderContent.contains("merged_into_call"))
    }

    @Test
    func test_dispatch_when_merge_would_exceed_max_batch_size_then_calls_dispatch_separately() async throws {
        // Given a 60-entry payload + a 60-entry payload; total 120 > 100 max so merge is skipped.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let firstUpdates = (0..<60).map { #"{"target":"A\#($0)"}"# }.joined(separator: ",")
        let secondUpdates = (0..<60).map { #"{"target":"B\#($0)"}"# }.joined(separator: ",")
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: "{\"updates\":[\(firstUpdates)]}")
        )
        let secondCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_update", arguments: "{\"updates\":[\(secondUpdates)]}")
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .toolCall(secondCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(60)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Bulk update") {}

        // Then merger gave up; first dispatches, cap-1 rejects the second.
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        let secondaryMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_2" }
        let content = try #require(secondaryMessage?.content)
        #expect(content.contains("per_tool_cap_exceeded"))
        #expect(!content.contains("merged_into_call"))
    }

    @Test
    func test_dispatch_when_calls_are_different_tools_then_no_merge() async throws {
        // Given a products_update next to an orders_list - no merge across tool boundaries.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let updateCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}]}"#)
        )
        let listCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "orders_list", arguments: #"{}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(updateCall), .toolCall(listCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool, listTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(1)]))))
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update then list") {}

        // Then both tools execute independently.
        let updateInvocations = await registry.invocationCount(for: "products_update")
        let listInvocations = await registry.invocationCount(for: "orders_list")
        #expect(updateInvocations == 1)
        #expect(listInvocations == 1)

        let capturedRequests = await chat.capturedRequests
        let mergeMarker = capturedRequests
            .flatMap { $0.messages }
            .first { ($0.content ?? "").contains("merged_into_call") }
        #expect(mergeMarker == nil)
    }

    @Test
    func test_dispatch_when_only_one_products_update_then_no_merge_attempted() async throws {
        // Given a single products_update call: behavior matches pre-merger.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let call = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}]}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(call), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(1)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A") {}

        // Then
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let lastArgs = await registry.lastArguments(for: "products_update")
        let unwrapped = try #require(lastArgs)
        #expect(unwrapped.contains("\"target\":\"A\""))

        let capturedRequests = await chat.capturedRequests
        let mergeMarker = capturedRequests
            .flatMap { $0.messages }
            .first { ($0.content ?? "").contains("merged_into_call") }
        #expect(mergeMarker == nil)
    }
}
