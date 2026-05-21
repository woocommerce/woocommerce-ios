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

    @Test
    func test_merge_when_three_products_update_in_one_batch_then_all_updates_present_once() async throws {
        // Given three adjacent products_update calls in one batch.
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
        let thirdCall = OpenAIChat.ToolCall(
            id: "call_3",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"C"}]}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .toolCall(secondCall), .toolCall(thirdCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(3)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A, B and C") {}

        // Then the three calls collapse into one dispatch carrying every update exactly once.
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let mergedArgs = await registry.lastArguments(for: "products_update")
        let unwrapped = try #require(mergedArgs)
        #expect(occurrences(of: "\"target\":\"A\"", in: unwrapped) == 1)
        #expect(occurrences(of: "\"target\":\"B\"", in: unwrapped) == 1)
        #expect(occurrences(of: "\"target\":\"C\"", in: unwrapped) == 1)

        let capturedRequests = await chat.capturedRequests
        let mergedSecondaries = capturedRequests
            .flatMap { $0.messages }
            .filter { $0.role == .tool && ($0.content ?? "").contains("merged_into_call") }
            .compactMap { $0.toolCallID }
        #expect(Set(mergedSecondaries) == ["call_2", "call_3"])
    }

    @Test
    func test_merge_when_non_adjacent_same_tool_calls_then_only_adjacent_merge() async throws {
        // Given products_update, products_list, products_update: the two updates are not adjacent.
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let listTool = AITool(name: "products_list",
                              description: "List products",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstUpdate = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"A"}]}"#)
        )
        let listCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "products_list", arguments: #"{}"#)
        )
        let secondUpdate = OpenAIChat.ToolCall(
            id: "call_3",
            function: .init(name: "products_update", arguments: #"{"updates":[{"target":"B"}]}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstUpdate), .toolCall(listCall), .toolCall(secondUpdate), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool, listTool])
        await registry.setResult(for: "products_update",
                                 result: .success(.init(toolName: "products_update",
                                                        structured: .object(["updated": .int(1)]))))
        await registry.setResult(for: "products_list",
                                 result: .success(.init(toolName: "products_list",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A, list, update B") {}

        // Then the two updates never merge; only the first dispatches and cap-1 rejects the second.
        let updateInvocations = await registry.invocationCount(for: "products_update")
        #expect(updateInvocations == 1)

        let capturedRequests = await chat.capturedRequests
        let mergeMarker = capturedRequests
            .flatMap { $0.messages }
            .first { ($0.content ?? "").contains("merged_into_call") }
        #expect(mergeMarker == nil)

        let secondUpdateMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_3" }
        let content = try #require(secondUpdateMessage?.content)
        #expect(content.contains("per_tool_cap_exceeded"))
    }

    @Test
    func test_merge_when_one_call_has_empty_updates_then_merge_skipped() async throws {
        // Given two products_update calls where the second omits the updates array entirely, so the
        // merger returns nil rather than silently dropping it.
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
            function: .init(name: "products_update", arguments: #"{"note":"no updates here"}"#)
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
                                                        structured: .object(["updated": .int(1)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Update A then nothing") {}

        // Then the calls stay split and cap-1 rejects the leftover second call.
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        let mergeMarker = capturedRequests
            .flatMap { $0.messages }
            .first { ($0.content ?? "").contains("merged_into_call") }
        #expect(mergeMarker == nil)

        let secondMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_2" }
        let content = try #require(secondMessage?.content)
        #expect(content.contains("per_tool_cap_exceeded"))
    }

    @Test
    func test_cap_when_two_split_products_update_in_one_batch_then_second_rejected() async throws {
        // Given two products_update calls in one batch whose updates overflow maxBatchSize, so they
        // stay split. The in-batch approval count must trip cap-1 on the second within the same batch.
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
        for try await _ in orchestrator.run(prompt: "Bulk update twice") {}

        // Then only one call dispatches and the second is capped within the same batch.
        let invocations = await registry.invocationCount(for: "products_update")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        let secondMessage = capturedRequests
            .flatMap { $0.messages }
            .first { $0.role == .tool && $0.toolCallID == "call_2" }
        let content = try #require(secondMessage?.content)
        #expect(content.contains("per_tool_cap_exceeded"))
    }

    @Test
    func test_merge_overflow_boundary_then_merges_at_max_and_splits_above() async throws {
        // Given updates summing to exactly maxBatchSize (100): the batch merges into one dispatch.
        let atMaxArgs = try await runProductsUpdateBatch(firstCount: 50, secondCount: 50)
        #expect(atMaxArgs.invocations == 1)
        let mergedArgs = try #require(atMaxArgs.lastArguments)
        #expect(mergedArgs.contains("\"target\":\"A0\""))
        #expect(mergedArgs.contains("\"target\":\"B49\""))
        #expect(!atMaxArgs.sawCapRejection)

        // Given updates summing to maxBatchSize + 1 (101): the merger gives up and the calls stay
        // split, so the first dispatches and cap-1 rejects the second.
        let overMaxArgs = try await runProductsUpdateBatch(firstCount: 50, secondCount: 51)
        #expect(overMaxArgs.invocations == 1)
        #expect(overMaxArgs.sawCapRejection)
    }

    private struct ProductsUpdateBatchResult {
        let invocations: Int
        let lastArguments: String?
        let sawCapRejection: Bool
    }

    private func runProductsUpdateBatch(firstCount: Int, secondCount: Int) async throws -> ProductsUpdateBatchResult {
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let firstUpdates = (0..<firstCount).map { #"{"target":"A\#($0)"}"# }.joined(separator: ",")
        let secondUpdates = (0..<secondCount).map { #"{"target":"B\#($0)"}"# }.joined(separator: ",")
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
                                                        structured: .object(["updated": .int(1)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        for try await _ in orchestrator.run(prompt: "Bulk update boundary") {}

        let invocations = await registry.invocationCount(for: "products_update")
        let lastArguments = await registry.lastArguments(for: "products_update")
        let capturedRequests = await chat.capturedRequests
        let sawCapRejection = capturedRequests
            .flatMap { $0.messages }
            .contains { ($0.content ?? "").contains("per_tool_cap_exceeded") }
        return ProductsUpdateBatchResult(invocations: invocations,
                                         lastArguments: lastArguments,
                                         sawCapRejection: sawCapRejection)
    }

    private func occurrences(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        var count = 0
        var searchRange = haystack.startIndex..<haystack.endIndex
        while let found = haystack.range(of: needle, range: searchRange) {
            count += 1
            searchRange = found.upperBound..<haystack.endIndex
        }
        return count
    }
}
