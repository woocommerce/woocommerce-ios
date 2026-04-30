import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct AssistantControllerTests {

    @Test
    func test_send_when_called_during_active_task_then_no_op() async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setAutoFinishStreams(false)
        await backend.setScriptedYields([[], []])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("first")
        await backend.awaitTurnStarted(at: 0)
        controller.send("second")

        // Then
        let receivedTurns = await backend.receivedTurns
        #expect(receivedTurns.count == 1)
        #expect(receivedTurns.first?.prompt == "first")
        #expect(controller.canSend == false)

        await backend.finishOldestStream()
    }

    @Test
    func test_send_when_called_with_whitespace_then_no_op() async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setScriptedYields([])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("   \n\t  ")
        controller.send("")

        // Then
        let receivedTurns = await backend.receivedTurns
        #expect(receivedTurns.isEmpty)
        #expect(controller.conversation.messages.isEmpty)
    }

    @Test
    func test_send_when_orchestrator_emits_textChunk_then_appends_to_active_assistant_message()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setScriptedYields([
            [.event(.textChunk("Hello ")),
             .event(.textChunk("world")),
             .event(.completed(routeConfidence: nil))]
        ])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("hi")
        await controller.activeTask?.value

        // Then
        let messages = controller.conversation.messages
        #expect(messages.count == 2)
        let assistant = try #require(messages.last)
        #expect(assistant.role == .assistant)
        #expect(assistant.isStreaming == false)
        let text: String? = assistant.segments.compactMap { segment -> String? in
            if case .text(_, let content) = segment { return content }
            return nil
        }.first
        #expect(text == "Hello world")
    }

    @Test
    func test_cancel_when_proposal_pending_then_resumes_with_approved_false() async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setScriptedYields([])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)
        let proposalID = UUID()

        // When
        controller.cancelProposal(proposalID)
        await backend.awaitProposalCancelled(proposalID)

        // Then
        let cancelled = await backend.cancelledProposalIDs
        #expect(cancelled.contains(proposalID))
    }

    @Test
    func test_run_when_stale_turn_finishes_after_new_send_then_does_not_clear_activeTask()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setAutoFinishStreams(false)
        await backend.setScriptedYields([[], []])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("first")
        await backend.awaitTurnStarted(at: 0)
        controller.cancel()
        // Start turn 2 while turn 1's stream is still open and the older Task
        // hasn't reached its cleanup yet. With the per-turn UUID token, the
        // older cleanup must skip clearing `activeTask` once the newer send
        // bumps the token; without it, this is where the chat freezes after
        // a follow-up question.
        controller.send("second")
        await backend.awaitTurnStarted(at: 1)
        let secondTask = controller.activeTask
        await backend.finishOldestStream()
        await backend.awaitTurnFinished(at: 0)

        // Then
        #expect(controller.canSend == false)
        #expect(secondTask != nil)
        let turns = await backend.receivedTurns
        #expect(turns.map(\.prompt) == ["first", "second"])

        await backend.finishOldestStream()
        await secondTask?.value
    }

    @Test
    func test_run_when_stale_turn_finishes_after_new_send_then_does_not_overwrite_new_turn_streaming_state()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setAutoFinishStreams(false)
        await backend.setScriptedYields([
            [],
            [.event(.textChunk("hi from B"))]
        ])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("first")
        await backend.awaitTurnStarted(at: 0)
        controller.cancel()
        controller.send("second")
        await backend.awaitTurnStarted(at: 1)
        let secondTask = controller.activeTask
        await Self.awaitStreamingState(controller, equals: .streaming)
        await backend.finishOldestStream()
        await backend.awaitTurnFinished(at: 0)

        // Then
        #expect(controller.conversation.streamingState == .streaming)

        await backend.finishOldestStream()
        await secondTask?.value
    }

    @Test
    func test_run_when_stale_turn_naturally_completes_after_new_send_then_does_not_clear_activeTask()
    async throws {
        // Given
        // Turn A finishes naturally between the user issuing it and the user
        // following up; B is sent after A's stream finished but before A's
        // post-loop cleanup necessarily ran on MainActor.
        let backend = MockAssistantBackend()
        await backend.setAutoFinishStreams(false)
        await backend.setScriptedYields([
            [.event(.textChunk("from A")), .event(.completed(routeConfidence: nil))],
            [.event(.textChunk("from B"))]
        ])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("first")
        await backend.awaitTurnStarted(at: 0)
        await backend.finishOldestStream()
        await controller.activeTask?.value
        controller.send("second")
        await backend.awaitTurnStarted(at: 1)
        let secondTask = controller.activeTask
        await Self.awaitStreamingState(controller, equals: .streaming)

        // Then
        #expect(controller.canSend == false)
        #expect(controller.conversation.streamingState == .streaming)

        await backend.finishOldestStream()
        await secondTask?.value
    }

    @Test
    func test_cancel_when_stream_in_flight_then_streamingState_idle_and_no_orphan_task()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        await backend.setAutoFinishStreams(false)
        await backend.setScriptedYields([
            [.event(.textChunk("partial"))]
        ])
        let controller = AssistantController(backend: backend,
                                             context: Self.defaultContext)

        // When
        controller.send("hi")
        await backend.awaitTurnStarted(at: 0)
        let inFlight = controller.activeTask
        controller.cancel()

        // Then
        #expect(controller.conversation.streamingState == .idle)
        #expect(controller.activeTask == nil)

        await backend.finishOldestStream()
        await inFlight?.value
        let messageCountBeforeLateYield = controller.conversation.messages.count
        await backend.finishOldestStream()
        #expect(controller.conversation.messages.count == messageCountBeforeLateYield)
    }

    private static let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    /// Suspends until `streamingState` matches `target`, using observation
    /// tracking instead of polling. Re-arms after each willSet fire because
    /// `onChange` fires once per transition.
    private static func awaitStreamingState(
        _ controller: AssistantController,
        equals target: AssistantConversation.StreamingState
    ) async {
        if controller.conversation.streamingState == target { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            armObservation(controller, target: target, continuation: continuation)
        }
    }

    private static func armObservation(
        _ controller: AssistantController,
        target: AssistantConversation.StreamingState,
        continuation: CheckedContinuation<Void, Never>
    ) {
        withObservationTracking {
            _ = controller.conversation.streamingState
        } onChange: {
            Task { @MainActor in
                if controller.conversation.streamingState == target {
                    continuation.resume()
                } else {
                    armObservation(controller, target: target, continuation: continuation)
                }
            }
        }
    }
}
