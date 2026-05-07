import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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
        let consumerTask = Task<Void, Never> {
            do {
                for try await event in orchestrator.run(prompt: "Mark order 42 processing") {
                    if case .confirmationRequired = event {
                        await confirmationSeen.signal()
                    }
                }
            } catch {
                // Cancellation propagates here once the consumer task is cancelled.
            }
        }
        await confirmationSeen.wait()
        consumerTask.cancel()
        await consumerTask.value
        let outcome = await orchestrator.awaitTermination()

        // Then
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 0)
        #expect(outcome == .stopped)
    }

    @Test
    func test_emptyList_nudge_when_summary_object_carries_count_zero_then_nudge_fires() async throws {
        // Given a list-shaped summary tool whose canonical empty result is
        // `{"count": 0, ...}` rather than a top-level `[]`.
        let listTool = AITool(name: "products_search",
                              description: "Search products",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        let firstCall = OpenAIChat.ToolCall(id: "call_1",
                                            function: .init(name: "products_search",
                                                            arguments: "{\"search\":\"scarf\"}"))
        let retryCall = OpenAIChat.ToolCall(id: "call_2",
                                            function: .init(name: "products_search",
                                                            arguments: "{\"search\":\"scarves\"}"))
        await chat.setScriptedTurns([
            [.toolCall(firstCall), .completed(.toolCalls)],
            [.toolCall(retryCall), .completed(.toolCalls)],
            [.textDelta("No matches."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "products_search",
                                 result: .success(.init(toolName: "products_search",
                                                        structured: .object(["count": .int(0)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Show scarves") {}

        // Then a nudge system message about not retrying spelling variants reached the model.
        let captured = await chat.capturedRequests
        let nudged = captured.contains { request in
            request.messages.contains { message in
                guard message.role == .system, let content = message.content else { return false }
                return content.contains("`products_search` returned no matches")
            }
        }
        #expect(nudged)
    }

    @Test
    func test_emptyList_nudge_when_assistant_emits_parallel_calls_then_pairs_results_by_toolCallID() async throws {
        // Given two parallel list calls in the same assistant message: the first returns
        // empty, the second returns one row. Pairing by position-of-next-message would
        // associate both calls with whichever tool-result message comes first; pairing
        // by toolCallID associates each call to its own result.
        let ordersList = AITool(name: "orders_list",
                                description: "List orders",
                                parametersSchema: .object([:]),
                                safetyLevel: .safe)
        let customersList = AITool(name: "customers_list",
                                   description: "List customers",
                                   parametersSchema: .object([:]),
                                   safetyLevel: .safe)
        let chat = MockAIChatService()
        let ordersCall = OpenAIChat.ToolCall(id: "call_orders",
                                             function: .init(name: "orders_list", arguments: "{}"))
        let customersCall = OpenAIChat.ToolCall(id: "call_customers",
                                                function: .init(name: "customers_list", arguments: "{}"))
        await chat.setScriptedTurns([
            [.toolCall(ordersCall), .toolCall(customersCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([ordersList, customersList])
        await registry.setResult(for: "customers_list",
                                 result: .success(.init(toolName: "customers_list",
                                                        structured: .object(["count": .int(0)]))))
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(3)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Anything") {}

        // Then only `customers_list` (the empty one) gets a nudge - `orders_list` is non-empty.
        let captured = await chat.capturedRequests
        let systemMessages = captured.flatMap { $0.messages }.filter { $0.role == .system }
        let customersNudgeFired = systemMessages.contains {
            ($0.content ?? "").contains("`customers_list` returned no matches")
        }
        let ordersNudgeFired = systemMessages.contains {
            ($0.content ?? "").contains("`orders_list` returned no matches")
        }
        #expect(customersNudgeFired)
        #expect(!ordersNudgeFired)
    }

    @Test
    func test_run_when_completed_with_nil_finish_reason_then_emits_upstreamFailure() async throws {
        // Given a transport that emits `.completed(nil)` - a malformed stream where no
        // chunk carried `finish_reason`. Treated identically to a stream that ended
        // without any `.completed` event at all.
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Partial..."), .completed(nil)]
        ])
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
        #expect(failedEvent?.kind == .upstreamFailure)

        let outcome = await orchestrator.lastOutcome
        if case .failed = outcome {
            #expect(true)
        } else {
            Issue.record("Expected lastOutcome == .failed, got \(String(describing: outcome))")
        }
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
    func test_run_when_success_with_uiStructured_then_emits_synthetic_toolResult_and_cardRender_events() async throws {
        // Given
        let listTool = AITool(name: "show_cards",
                              description: "Render cards",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let toolCall = OpenAIChat.ToolCall(
            id: "call_show",
            function: .init(name: "show_cards", arguments: #"{}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let card = RenderedCardPayload(family: .order,
                                       id: "42",
                                       element: .object(["id": .int(42)]))
        let success = ToolResult.Success(toolName: "show_cards",
                                         structured: .object(["rendered": .int(1)]),
                                         uiStructured: UIStructured(cards: [card]))
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "show_cards", result: .success(success))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Show order 42") {
            events.append(event)
        }

        // Then
        let cardRenderIDs: [String] = events.compactMap { event in
            if case .cardRender(let id) = event { return id }
            return nil
        }
        #expect(cardRenderIDs.count == 1)
        let renderID = try #require(cardRenderIDs.first)
        #expect(renderID.hasPrefix("call_show:card:"))

        let syntheticToolResult = events.first { event in
            if case .toolResult(let id, _, _) = event, id == renderID { return true }
            return false
        }
        #expect(syntheticToolResult != nil)
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

    @Test
    func test_run_when_one_safe_tool_then_stop_then_completes_with_tool_result_in_history() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_list", arguments: #"{"per_page":3}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Here are your orders."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(3)]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "List orders") {
            events.append(event)
        }

        // Then
        let invocations = await registry.invocationCount(for: "orders_list")
        #expect(invocations == 1)
        #expect(events.contains(.textChunk("Here are your orders.")))
        #expect(events.contains(.completed(routeConfidence: nil)))

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count == 2)
        let secondRequestToolMessage = capturedRequests[1].messages.first { $0.role == .tool && $0.toolCallID == "call_1" }
        let content = try #require(secondRequestToolMessage?.content)
        #expect(content.contains("\"count\":3"))

        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)
    }

    @Test
    func test_run_when_unknown_tool_name_from_model_then_synthetic_error_without_registry_execution() async throws {
        // Given
        let registeredTool = AITool(name: "orders_list",
                                    description: "List orders",
                                    parametersSchema: .object([:]),
                                    safetyLevel: .safe)
        let unknownToolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "imaginary_tool", arguments: #"{}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(unknownToolCall), .completed(.toolCalls)],
            [.textDelta("Sorry, I cannot do that."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([registeredTool])
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        for try await _ in orchestrator.run(prompt: "Use the imaginary tool") {}

        // Then
        let imaginaryInvocations = await registry.invocationCount(for: "imaginary_tool")
        let registeredInvocations = await registry.invocationCount(for: "orders_list")
        #expect(imaginaryInvocations == 0)
        #expect(registeredInvocations == 0)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count == 2)
        let toolMessage = capturedRequests[1].messages.first { $0.role == .tool && $0.toolCallID == "call_1" }
        let content = try #require(toolMessage?.content)
        #expect(content.contains("Unknown tool"))
    }

    @Test
    func test_run_when_tool_returns_invalidToolCall_failure_then_loop_continues_with_error_in_history() async throws {
        // Given
        let listTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_list", arguments: #"{not even valid json"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("I had trouble understanding that."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([listTool])
        await registry.setResult(for: "orders_list",
                                 result: .failed(.init(toolName: "orders_list",
                                                       kind: .invalidToolCall,
                                                       reason: "Malformed arguments JSON.")))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "List orders") {
            events.append(event)
        }

        // Then
        #expect(events.contains(.completed(routeConfidence: nil)))
        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)

        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count == 2)
        let toolMessage = capturedRequests[1].messages.first { $0.role == .tool && $0.toolCallID == "call_1" }
        let content = try #require(toolMessage?.content)
        #expect(content.contains("Malformed arguments JSON"))
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
