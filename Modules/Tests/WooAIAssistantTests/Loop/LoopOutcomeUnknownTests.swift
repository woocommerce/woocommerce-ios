import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopOutcomeUnknownTests {

    @Test
    func test_loop_when_write_tool_returns_outcome_unknown_then_turn_terminates_without_further_tool_calls() async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"processing"}"#)
        )
        let retryCall = OpenAIChat.ToolCall(
            id: "call_2",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"completed"}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(retryCall), .completed(.toolCalls)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "orders_update",
                                 result: .failed(.init(toolName: "orders_update",
                                                       kind: .outcomeUnknown,
                                                       reason: "Network dropped after request was sent.")))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Mark order 42 processing") {
            events.append(event)
        }

        // Then
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 1)

        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count == 1)

        let textChunks: [String] = events.compactMap { event in
            if case .textChunk(let text) = event { return text }
            return nil
        }
        #expect(textChunks.contains { $0.contains("check your store") })

        let failureKinds: [AssistantErrorKind] = events.compactMap { event in
            if case .failed(let error) = event { return error.kind }
            return nil
        }
        #expect(failureKinds.contains(.outcomeUnknown))
    }

    @Test
    func test_loop_when_read_tool_returns_outcome_unknown_then_loop_continues() async throws {
        // Given
        let readTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_list", arguments: #"{"status":"processing"}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.textDelta("I'll let you know once the list comes back."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([readTool])
        await registry.setResult(for: "orders_list",
                                 result: .failed(.init(toolName: "orders_list",
                                                       kind: .outcomeUnknown,
                                                       reason: "Read timed out.")))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Show processing orders") {
            events.append(event)
        }

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count == 2)

        let textChunks: [String] = events.compactMap { event in
            if case .textChunk(let text) = event { return text }
            return nil
        }
        #expect(!textChunks.contains { $0.contains("check your store") })
        #expect(textChunks.contains { $0.contains("let you know") })

        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)
    }

    @Test
    func test_loop_when_write_outcome_unknown_then_partial_success_reason_passes_through_to_failure_event() async throws {
        // Given
        let writeTool = AITool(name: "products_update",
                               description: "Update products",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let call = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "products_update", arguments: #"{"updates":[{"id":42},{"id":43}]}"#)
        )
        let receiptJSON = #"{"results":[{"id":42,"status":"success"},{"id":43,"status":"outcome_unknown"}]}"#
        let reason = "One or more product updates did not get a confirmed response. \(receiptJSON)"
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(call), .completed(.toolCalls)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "products_update",
                                 result: .failed(.init(toolName: "products_update",
                                                       kind: .outcomeUnknown,
                                                       reason: reason)))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Bump prices on 42 and 43") {
            events.append(event)
        }

        // Then
        let failureMessages: [String] = events.compactMap { event in
            if case .failed(let error) = event { return error.message }
            return nil
        }
        let receiptFailure = try #require(failureMessages.first { $0.contains("id\":42") })
        #expect(receiptFailure.contains("success"))
        #expect(receiptFailure.contains("outcome_unknown"))
    }

    @Test
    func test_outcome_unknown_transcript_payload_has_minimal_shape_with_reason_in_detail() async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .unsafe)
        let call = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42}"#)
        )
        let reason = "Network dropped after request was sent."
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(call), .completed(.toolCalls)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([writeTool])
        await registry.setResult(for: "orders_update",
                                 result: .failed(.init(toolName: "orders_update",
                                                       kind: .outcomeUnknown,
                                                       reason: reason)))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Mark order 42 processing") {
            events.append(event)
        }

        // Then
        let toolCompletedPayloads: [String] = events.compactMap { event -> String? in
            guard case .toolCallCompleted(_, _, let payload) = event else { return nil }
            return payload
        }
        let payload = try #require(toolCompletedPayloads.first { $0.contains("\"outcome\":\"unknown\"") })
        let data = try #require(payload.data(using: .utf8))
        let parsed = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(parsed["outcome"] as? String == "unknown")
        #expect(parsed["tool"] as? String == "orders_update")
        #expect(parsed["detail"] as? String == reason)
        #expect(parsed["advice"] == nil)
        #expect(parsed["receipt"] == nil)
    }
}
