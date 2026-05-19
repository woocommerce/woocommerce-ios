import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantShowCardsTelemetryTests {

    private let telemetryContext = AssistantTelemetryContext(conversationID: "c",
                                                             requestID: "r",
                                                             messageID: "m")

    @Test
    func test_show_cards_success_when_counts_are_safe_then_emits_show_cards_processed() async throws {
        // Given
        let showCardsTool = AITool(name: ShowCardsTool.name,
                                   description: "Show cards",
                                   parametersSchema: .object([:]),
                                   safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: ShowCardsTool.name,
                                             arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([showCardsTool])
        let structured: AnyCodableJSON = .object([
            "requested": .int(3),
            "rendered": .int(1),
            "missing_refs": .array([.object(["reason": .string("not_found")])]),
            "rejected_refs": .array([.object(["reason": .string("duplicate")])])
        ])
        await registry.setResult(for: ShowCardsTool.name,
                                 result: .success(.init(toolName: ShowCardsTool.name,
                                                        structured: structured)))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "show me",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let counts = events.compactMap { event -> ShowCardsCounts? in
            if case .showCardsProcessed(_, let req, let ren, let miss, let rej) = event {
                return ShowCardsCounts(requestedCount: req,
                                       renderedCount: ren,
                                       missingCount: miss,
                                       rejectedCount: rej)
            }
            return nil
        }
        try #require(counts.count == 1)
        #expect(counts[0] == ShowCardsCounts(requestedCount: 3,
                                             renderedCount: 1,
                                             missingCount: 1,
                                             rejectedCount: 1))
    }

    @Test
    func test_show_cards_when_payload_malformed_then_only_emits_tool_failure_not_processed() async throws {
        // Given
        let showCardsTool = AITool(name: ShowCardsTool.name,
                                   description: "Show cards",
                                   parametersSchema: .object([:]),
                                   safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: ShowCardsTool.name,
                                             arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([showCardsTool])
        await registry.setResult(for: ShowCardsTool.name,
                                 result: .failed(.init(toolName: ShowCardsTool.name,
                                                       kind: .invalidToolCall,
                                                       reason: "bad args")))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "show me",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let processedEvents = events.filter { event in
            if case .showCardsProcessed = event { return true }
            return false
        }
        let toolFailures = events.compactMap { event -> AssistantTelemetryErrorKind? in
            if case .toolCallCompleted(_, ShowCardsTool.name, .failure, let kind, _) = event {
                return kind
            }
            return nil
        }
        #expect(processedEvents.isEmpty)
        #expect(toolFailures == [.validationError])
    }

    @Test
    func test_show_cards_success_with_unparseable_structured_then_skips_processed_event() async throws {
        // Given
        let showCardsTool = AITool(name: ShowCardsTool.name,
                                   description: "Show cards",
                                   parametersSchema: .object([:]),
                                   safetyLevel: .safe)
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(.init(id: "call-1",
                             function: .init(name: ShowCardsTool.name,
                                             arguments: #"{}"#))),
             .completed(.toolCalls)],
            [.completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([showCardsTool])
        await registry.setResult(for: ShowCardsTool.name,
                                 result: .success(.init(toolName: ShowCardsTool.name,
                                                        structured: .array([.int(1)]))))
        let tracker = await RecordingAssistantTelemetryTracker()
        let orchestrator = await AgenticLoopOrchestrator(chatService: chat,
                                                         toolRegistry: registry,
                                                         telemetryTracker: tracker)

        // When
        for try await _ in orchestrator.run(prompt: "show me",
                                            priorMessages: [],
                                            telemetryContext: telemetryContext) {}

        // Then
        let events = await tracker.events
        let processedEvents = events.filter { event in
            if case .showCardsProcessed = event { return true }
            return false
        }
        let successCompletions = events.filter { event in
            if case .toolCallCompleted(_, ShowCardsTool.name, .success, _, _) = event { return true }
            return false
        }
        #expect(processedEvents.isEmpty)
        #expect(successCompletions.count == 1)
    }
}
