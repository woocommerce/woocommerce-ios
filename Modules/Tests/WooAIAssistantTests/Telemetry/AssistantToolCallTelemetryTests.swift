import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantToolCallTelemetryTests {

    private let telemetryContext = AssistantTelemetryContext(conversationID: "c",
                                                             requestID: "r",
                                                             messageID: "m")

    @Test
    func test_tool_succeeds_when_executed_then_emits_success_toolCallCompleted() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: "orders_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(1)]))))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "list",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletions = events.compactMap { event -> (String, AssistantTelemetryToolStatus)? in
            if case .toolCallCompleted(_, let name, let status, _, _) = event {
                return (name, status)
            }
            return nil
        }
        try #require(toolCompletions.count == 1)
        #expect(toolCompletions[0].0 == "orders_list")
        #expect(toolCompletions[0].1 == .success)
    }

    @Test
    func test_tool_fails_when_handler_returns_failed_then_emits_failure_with_mapped_error_kind() async throws {
        // Given
        let safeTool = AITool(name: "orders_update",
                              description: "Update orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: "orders_update", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_update",
                                 result: .failed(.init(toolName: "orders_update",
                                                       kind: .network,
                                                       reason: "boom")))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletions = events.compactMap { event -> AssistantTelemetryErrorKind? in
            if case .toolCallCompleted(_, _, .failure, let errorKind, _) = event { return errorKind }
            return nil
        }
        #expect(toolCompletions.contains(.network))
    }

    @Test
    func test_unknown_tool_when_dispatched_then_emits_unknown_tool_name_validation_error() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: "no_such_tool", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletions = events.compactMap { event -> (String, AssistantTelemetryErrorKind?)? in
            if case .toolCallCompleted(_, let name, .failure, let errorKind, _) = event {
                return (name, errorKind)
            }
            return nil
        }
        #expect(toolCompletions.contains(where: { $0.0 == "unknown" && $0.1 == .validationError }))
        #expect(!toolCompletions.contains(where: { $0.0 == "no_such_tool" }))
    }

    @Test
    func test_hallucinated_tool_name_with_pii_content_then_canonicalizes_to_unknown() async throws {
        // Given
        let pii = "open_order_admin@example.com"
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: pii, arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolNames = events.compactMap { event -> String? in
            if case .toolCallCompleted(_, let name, _, _, _) = event { return name }
            return nil
        }
        #expect(toolNames.allSatisfy { !$0.contains("@") })
        #expect(toolNames.contains("unknown"))
        #expect(!toolNames.contains(pii))
    }

    @Test
    func test_awaitingConfirmation_when_tool_short_circuits_safety_gate_then_emits_validation_error() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: "orders_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        let proposal = ToolResult.ConfirmationProposal(toolName: "orders_list",
                                                       proposal: .object([:]))
        await registry.setResult(for: "orders_list", result: .awaitingConfirmation(proposal))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let errorKinds = events.compactMap { event -> AssistantTelemetryErrorKind? in
            if case .toolCallCompleted(_, "orders_list", .failure, let errorKind, _) = event { return errorKind }
            return nil
        }
        #expect(errorKinds == [.validationError])
    }

    @Test
    func test_per_tool_cap_when_exceeded_then_emits_failure_validation_error() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        let calls = (0..<5).map { i in
            ChatStreamEvent.toolCall(.init(id: "call_\(i)",
                                            function: .init(name: "orders_list",
                                                            arguments: #"{"page":\#(i + 1)}"#)))
        } + [.completed(.toolCalls)]
        await chat.setScriptedTurns([calls, [.completed(.stop)]])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         perToolPerTurnCap: 2,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let cappedEvents = events.filter { event in
            if case .toolCallCompleted(_, "orders_list", .failure, .validationError, _) = event {
                return true
            }
            return false
        }
        #expect(cappedEvents.count >= 1)
    }

    @Test
    func test_nil_registry_when_tools_dispatched_then_emits_failure_unknown_per_call() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: "orders_list", arguments: #"{}"#))),
             .toolCall(.init(id: "call-2",
                             function: .init(name: "products_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: nil,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletions = events.compactMap { event -> (String, AssistantTelemetryToolStatus, AssistantTelemetryErrorKind?)? in
            if case .toolCallCompleted(_, let name, let status, let errorKind, _) = event {
                return (name, status, errorKind)
            }
            return nil
        }
        #expect(toolCompletions.count == 2)
        #expect(toolCompletions.allSatisfy { $0.0 == "unknown" })
        #expect(toolCompletions.allSatisfy { $0.1 == .failure })
        #expect(toolCompletions.allSatisfy { $0.2 == .unknown })
    }

    @Test
    func test_intra_batch_duplicate_tool_calls_when_dispatched_then_emits_telemetry_only_for_primary() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1", function: .init(name: "orders_list", arguments: #"{}"#))),
             .toolCall(.init(id: "call-2", function: .init(name: "orders_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletionsForOrdersList = events.filter { event in
            if case .toolCallCompleted(_, "orders_list", _, _, _) = event { return true }
            return false
        }
        #expect(toolCompletionsForOrdersList.count == 1)
    }

    @Test
    func test_cached_replay_when_duplicate_call_then_emits_no_tool_call_telemetry() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1", function: .init(name: "orders_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.toolCall(.init(id: "call-2", function: .init(name: "orders_list", arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "go",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let toolCompletionsForOrdersList = events.filter { event in
            if case .toolCallCompleted(_, "orders_list", _, _, _) = event { return true }
            return false
        }
        #expect(toolCompletionsForOrdersList.count == 1)
    }
}
