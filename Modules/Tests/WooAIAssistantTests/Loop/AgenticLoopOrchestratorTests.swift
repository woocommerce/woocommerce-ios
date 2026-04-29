import Foundation
import Testing
@testable import WooAIAssistant

struct AgenticLoopOrchestratorTests {

    @Test
    func test_run_when_chatService_emits_text_only_then_completes_without_tool_dispatch() async throws {
        // Given
        let chat = MockAIChatService()
        await chat.setScriptedTurns([
            [.textDelta("Hello"), .textDelta(" merchant"), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        let orchestrator = AgenticLoopOrchestrator(chatService: chat, toolRegistry: registry)

        // When
        var events: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "Hi") {
            events.append(event)
        }

        // Then
        #expect(events.contains(.textChunk("Hello")))
        #expect(events.contains(.textChunk(" merchant")))
        #expect(events.contains(.completed(routeConfidence: nil)))
        let invocations = await registry.invocationCount(for: "anything")
        #expect(invocations == 0)
        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)
    }

    @Test
    func test_run_when_tool_unsafe_then_emits_confirmationRequired_and_awaits_decision() async throws {
        // Given
        let unsafeTool = AITool(name: "orders_update",
                                description: "Update an order",
                                parametersSchema: .object([:]),
                                safetyLevel: .unsafe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"processing"}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Done."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([unsafeTool])
        await registry.setResult(for: "orders_update",
                                 result: .success(.init(toolName: "orders_update",
                                                        structured: .object(["id": .int(42),
                                                                             "status": .string("processing")]))))
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   safetyPolicy: DefaultSafetyPolicy())

        // When
        var events: [AssistantEvent] = []
        let stream = orchestrator.run(prompt: "Mark order 42 as processing")
        var pendingConfirmTask: Task<Void, Never>?
        for try await event in stream {
            events.append(event)
            if case .confirmationRequired(let proposal) = event {
                pendingConfirmTask = Task {
                    await orchestrator.confirm(proposalID: proposal.id)
                }
            }
        }
        await pendingConfirmTask?.value

        // Then
        let confirmationProposal: ToolProposal? = events.compactMap { event in
            if case .confirmationRequired(let proposal) = event {
                return proposal
            }
            return nil
        }.first
        let proposal = try #require(confirmationProposal)
        #expect(proposal.toolName == "orders_update")
        #expect(proposal.toolCallID == "call_1")
        #expect(proposal.preview.contains("42"))

        let resolved: Bool? = events.compactMap { event in
            if case .confirmationResolved(let proposalID, let approved) = event,
               proposalID == proposal.id {
                return approved
            }
            return nil
        }.first
        #expect(resolved == true)
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 1)
        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)
    }

    @Test
    func test_run_when_user_cancels_proposal_then_appends_userCancelled_tool_message_and_continues() async throws {
        // Given
        let unsafeTool = AITool(name: "orders_update",
                                description: "Update an order",
                                parametersSchema: .object([:]),
                                safetyLevel: .unsafe)
        let chat = MockAIChatService()
        let toolCall = OpenAIChat.ToolCall(
            id: "call_1",
            function: .init(name: "orders_update", arguments: #"{"id":42,"status":"processing"}"#)
        )
        await chat.setScriptedTurns([
            [.toolCall(toolCall), .completed(.toolCalls)],
            [.textDelta("Cancelled."), .completed(.stop)]
        ])
        let registry = MockToolRegistry()
        await registry.setAvailableTools([unsafeTool])
        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   safetyPolicy: DefaultSafetyPolicy())

        // When
        var events: [AssistantEvent] = []
        let stream = orchestrator.run(prompt: "Mark order 42 as processing")
        var pendingCancelTask: Task<Void, Never>?
        for try await event in stream {
            events.append(event)
            if case .confirmationRequired(let proposal) = event {
                pendingCancelTask = Task {
                    await orchestrator.cancel(proposalID: proposal.id)
                }
            }
        }
        await pendingCancelTask?.value

        // Then
        let cancelledResolution: Bool? = events.compactMap { event in
            if case .confirmationResolved(_, let approved) = event {
                return approved
            }
            return nil
        }.first
        #expect(cancelledResolution == false)
        let invocations = await registry.invocationCount(for: "orders_update")
        #expect(invocations == 0)

        // The model's follow-up turn should see a tool message in
        // its second-call request whose content is the user-
        // cancelled JSON envelope.
        let capturedRequests = await chat.capturedRequests
        #expect(capturedRequests.count >= 2)
        let secondRequest = capturedRequests[1]
        let toolMessage = secondRequest.messages.last { $0.role == .tool }
        let content = try #require(toolMessage?.content)
        #expect(content.contains("user_cancelled"))
        #expect(content.contains("User declined"))

        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .completed)
    }

    @Test
    func test_run_when_iteration_cap_hit_then_returns_maxIterations_outcome_with_synthetic_assistant_text() async throws {
        // Given
        let safeTool = AITool(name: "orders_list",
                              description: "List orders",
                              parametersSchema: .object([:]),
                              safetyLevel: .safe)
        let chat = MockAIChatService()
        let scriptedTurns: [[ChatStreamEvent]] = (0..<3).map { i in
            let call = OpenAIChat.ToolCall(
                id: "call_\(i)",
                function: .init(name: "orders_list",
                                arguments: #"{"page":\#(i + 1)}"#)
            )
            return [.toolCall(call), .completed(.toolCalls)]
        }
        await chat.setScriptedTurns(scriptedTurns)
        let registry = MockToolRegistry()
        await registry.setAvailableTools([safeTool])
        await registry.setResult(for: "orders_list",
                                 result: .success(.init(toolName: "orders_list",
                                                        structured: .object(["count": .int(0)]))))

        let orchestrator = AgenticLoopOrchestrator(chatService: chat,
                                                   toolRegistry: registry,
                                                   maxIterations: 3)

        // When
        var collected: [AssistantEvent] = []
        for try await event in orchestrator.run(prompt: "List everything") {
            collected.append(event)
        }

        // Then
        let textChunks: [String] = collected.compactMap { event in
            if case .textChunk(let text) = event { return text }
            return nil
        }
        #expect(textChunks.contains { $0.contains("a few more steps than expected") })
        #expect(collected.contains(.completed(routeConfidence: nil)))

        let outcome = await orchestrator.lastOutcome
        #expect(outcome == .maxIterations(iterations: 3))
    }
}
