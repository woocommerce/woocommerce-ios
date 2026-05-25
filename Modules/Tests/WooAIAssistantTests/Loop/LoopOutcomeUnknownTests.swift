import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct LoopOutcomeUnknownTests {

    @Test
    func test_outcomeUnknown_when_write_tool_returns_outcomeUnknown_then_emits_failed_event_with_outcomeUnknown_kind() async throws {
        // Given
        let writeTool = AITool(name: "orders_update",
                               description: "Update an order",
                               parametersSchema: .object([:]),
                               safetyLevel: .safe)
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"processing"}"#)
        )
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("I couldn't confirm the change. Check the order."), .completed(.stop)]
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
        let unknownFailure: AssistantError? = events.compactMap { event in
            if case .failed(let error) = event, error.kind == .outcomeUnknown {
                return error
            }
            return nil
        }.first
        let error = try #require(unknownFailure)
        #expect(error.message == "Network dropped after request was sent.")

        // The loop continued (model produced text after) so the
        // terminal outcome is still .completed, not .failed.
        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)

        // The model should have seen the outcome_unknown advice
        // tool message in its follow-up request.
        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 2)
        let secondRequest = capturedRequests[1]
        let toolMessage = secondRequest.messages.last { $0.role == .tool && $0.toolCallID == "call_1" }
        let content = try #require(toolMessage?.content)
        #expect(content.contains("\"outcome\":\"unknown\""))
        #expect(content.contains("verify"))
    }
}
