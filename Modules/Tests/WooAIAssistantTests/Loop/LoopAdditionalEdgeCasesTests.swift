import Foundation
import Testing
@testable import WooAIAssistant

struct LoopAdditionalEdgeCasesTests {

    @Test
    func test_run_when_tool_called_5_times_with_varying_args_then_5th_call_returns_per_tool_cap_envelope() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        var scriptedTurns: [[ChatStreamEvent]] = (0..<5).map { i in
            let call = OpenAIChat.ToolCall(
                id: "call_\(i)",
                function: .init(name: "orders_list",
                                arguments: #"{"page":\#(i + 1)}"#)
            )
            return [.toolCall(call), .completed(.toolCalls)]
        }
        scriptedTurns.append([.textDelta("All done."), .completed(.stop)])
        await chat.setScriptedTurns(scriptedTurns)
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   maxIterations: 7)

        // When
        for try await _ in orchestrator.run(prompt: "List everything") {}

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 4)

        let capturedRequests = await chat.capturedRequests
        let capExceededFound = capturedRequests.contains { request in
            request.messages.contains { message in
                guard message.role == .tool, let content = message.content else { return false }
                return content.contains("per_tool_cap_exceeded")
            }
        }
        #expect(capExceededFound)
    }

    @Test
    func test_dedupe_when_assistant_emits_two_identical_calls_in_one_batch_then_only_primary_dispatches() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let firstCall = OpenAIChat.ToolCall(
            id: "call_a",
            function: .init(name: "orders_list", arguments: #"{"status":"processing"}"#)
        )
        let duplicateCall = OpenAIChat.ToolCall(
            id: "call_b",
            function: .init(name: "orders_list", arguments: #"{"status":"processing"}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .toolCall(duplicateCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(3)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Show processing orders") {}

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 1)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 2)
        let secondRequest = capturedRequests[1]
        let primaryToolMessage = secondRequest.messages.first { $0.role == .tool && $0.toolCallID == "call_a" }
        let secondaryToolMessage = secondRequest.messages.first { $0.role == .tool && $0.toolCallID == "call_b" }
        let primaryContent = try #require(primaryToolMessage?.content)
        let secondaryContent = try #require(secondaryToolMessage?.content)
        #expect(primaryContent.contains("\"count\":3"))
        #expect(!primaryContent.contains("cached_result_reused"))
        #expect(secondaryContent.contains("cached_result_reused"))
    }

    @Test
    func test_run_when_stream_cancelled_during_confirmation_then_pending_continuations_resolve_false_and_outcome_is_stopped() async throws {
        // Given
        let unsafeTool = AITool(name: "orders_update",
                                description: "Update an order",
                                parametersSchema: .object([:]),
                                safetyLevel: .unsafe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([unsafeTool])
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   safetyPolicy: DefaultSafetyPolicy())
        let confirmationSeen = AsyncSignal()

        // When
        let consumerTask = Task {
            for try await event in orchestrator.run(prompt: "Mark order 42 processing") {
                if case .confirmationRequired = event {
                    await confirmationSeen.signal()
                    return
                }
            }
        }
        await confirmationSeen.wait()
        consumerTask.cancel()
        _ = try? await consumerTask.value
        try await Task.sleep(for: .milliseconds(100))

        // Then
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 0)
        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .stopped)
    }

    @Test
    func test_run_when_chatService_throws_mid_stream_then_emits_failed_and_lastOutcome_is_failed() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Partial...")]
        ])
        await chat.setStreamError(MockStreamError.upstream)
        let registry = MockToolRegistry()
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Anything") {
            events.append(event)
        }

        // Then
        let failedEvent: AssistantError? = events.compactMap { event in
            if case .failed(let error) = event { return error }
            return nil
        }.first
        #expect(failedEvent != nil)

        let outcome = await orchestrator.lastOutcome
        if case .failed = outcome {
            #expect(true)
        } else {
            Issue.record("Expected lastOutcome == .failed, got \(String(describing: outcome))")
        }
    }

    @Test
    func test_run_when_success_with_uiStructured_then_only_structured_appears_in_resubmitted_tool_message() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_list", arguments: #"{}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Found one."), .completed(.stop)]
        ])
        let uiOnlyCard = RenderedCardPayload(
            family: .order,
            id: "ui_only_marker_42",
            element: .object(["uiOnlyKey": .string("uiOnlyValue")])
        )
        let success = ToolResult.Success(
            toolName: "orders_list",
            structured: .object(["structuredKey": .string("structuredValue")]),
            uiStructured: UIStructured(cards: [uiOnlyCard])
        )
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list", result: .success(success))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "List orders") {}

        // Then
        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 2)
        let secondRequest = capturedRequests[1]
        let toolMessage = secondRequest.messages.first { $0.role == .tool && $0.toolCallID == "call_1" }
        let content = try #require(toolMessage?.content)
        #expect(content.contains("structuredValue"))
        #expect(!content.contains("ui_only_marker_42"))
        #expect(!content.contains("uiOnlyValue"))
    }
}

private enum MockStreamError: Error {
    case upstream
}

/// Single-shot signal so the test can wait for an event without polling.
private actor AsyncSignal {
    private var continuation: CheckedContinuation<Void, Never>?
    private var signaled = false

    func signal() {
        if let pending = continuation {
            continuation = nil
            pending.resume()
        } else {
            signaled = true
        }
    }

    func wait() async {
        if signaled {
            signaled = false
            return
        }
        await withCheckedContinuation { cont in
            continuation = cont
        }
    }
}
