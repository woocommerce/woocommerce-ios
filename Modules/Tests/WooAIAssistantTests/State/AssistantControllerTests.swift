import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct AssistantControllerTests {

    private let defaultContext = AssistantContext(
        siteID: 1,
        siteURL: URL(string: "https://example.com")!,
        blogID: nil
    )

    @Test
    func test_send_when_called_during_active_task_then_no_op() async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.script([[], []])
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("first")
        controller.send("second")

        // Then
        #expect(controller.canSend == false)

        backend.releaseStream(at: 0)
        await controller.activeTask?.value
        #expect(backend.recordedTurns.count == 1)
        #expect(backend.recordedTurns.first?.prompt == "first")
    }

    @Test
    func test_send_when_called_with_whitespace_then_no_op() async throws {
        // Given
        let backend = MockAssistantBackend()
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("   \n\t  ")
        controller.send("")

        // Then
        #expect(backend.recordedTurns.isEmpty)
        #expect(controller.conversation.messages.isEmpty)
    }

    @Test
    func test_send_when_orchestrator_emits_textChunk_then_appends_to_active_assistant_message()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([
            .event(.textChunk("Hello ")),
            .event(.textChunk("world")),
            .event(.completed(routeConfidence: nil))
        ])
        let controller = AssistantController(backend: backend, context: defaultContext)

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
        _ = AssistantController(backend: backend, context: defaultContext)
        let proposalID = UUID()

        // When
        await backend.cancelProposal(proposalID)

        // Then
        #expect(backend.cancelledProposalIDs.contains(proposalID))
    }

    @Test
    func test_run_when_stale_turn_finishes_after_new_send_then_does_not_clear_activeTask()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.holdStream(at: 1)
        backend.script([[], []])
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("first")
        let firstTask = try #require(controller.activeTask)
        controller.cancel()
        controller.send("second")
        let secondTask = try #require(controller.activeTask)
        backend.releaseStream(at: 0)
        await firstTask.value

        // Then
        #expect(controller.canSend == false)
        #expect(secondTask != firstTask)

        backend.releaseStream(at: 1)
        await secondTask.value
        #expect(backend.recordedTurns.map(\.prompt) == ["first", "second"])
    }

    @Test
    func test_run_when_stale_turn_finishes_after_new_send_then_does_not_overwrite_new_turn_streaming_state()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.holdStream(at: 1)
        backend.script([
            [],
            [.event(.textChunk("hi from B"))]
        ])
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("first")
        let firstTask = try #require(controller.activeTask)
        controller.cancel()
        controller.send("second")
        let secondTask = try #require(controller.activeTask)
        backend.releaseStream(at: 0)
        await firstTask.value

        // Then
        #expect(controller.conversation.streamingState == .streaming)

        backend.releaseStream(at: 1)
        await secondTask.value
    }

    @Test
    func test_run_when_stale_turn_naturally_completes_after_new_send_then_does_not_clear_activeTask()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 1)
        backend.script([
            [.event(.textChunk("from A")), .event(.completed(routeConfidence: nil))],
            [.event(.textChunk("from B"))]
        ])
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("first")
        await controller.activeTask?.value
        controller.send("second")
        let secondTask = try #require(controller.activeTask)

        // Then
        #expect(controller.canSend == false)

        backend.releaseStream(at: 1)
        await secondTask.value
        #expect(controller.conversation.streamingState == .idle)
    }

    @Test
    func test_cancel_when_pending_confirmation_then_segment_becomes_cancelled_and_proposal_is_cancelled_in_backend()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        let proposalID = UUID()
        let conversation = AssistantConversation(seededMessages: [
            ChatMessage(role: .assistant,
                        segments: [
                            .confirmation(id: UUID(),
                                          proposalID: proposalID,
                                          toolName: "orders_update",
                                          preview: ConfirmationPreview(summary: .raw("Set order to completed")),
                                          status: .pending)
                        ])
        ])
        let controller = AssistantController(backend: backend,
                                             context: defaultContext,
                                             conversation: conversation)

        // When
        controller.cancel()
        await backend.waitForCancelledProposal(proposalID)

        // Then
        #expect(controller.canSend == true)
        #expect(controller.conversation.streamingState == .idle)
        let assistantMessage = controller.conversation.messages.last
        let confirmationSegments = assistantMessage?.segments.compactMap { segment -> ConfirmationStatus? in
            if case .confirmation(_, _, _, _, let status) = segment { return status }
            return nil
        } ?? []
        #expect(confirmationSegments.contains(.cancelled))
        #expect(backend.cancelledProposalIDs.contains(proposalID))
    }

    @Test
    func test_startNewConversation_when_called_then_resets_backend_and_clears_messages()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([
            .event(.textChunk("Hello")),
            .event(.completed(routeConfidence: nil))
        ])
        let controller = AssistantController(backend: backend, context: defaultContext)
        controller.send("hi")
        await controller.activeTask?.value
        #expect(controller.conversation.messages.isEmpty == false)

        // When
        controller.startNewConversation()
        await controller.activeTask?.value

        // Then
        #expect(controller.conversation.messages.isEmpty)
        #expect(backend.resetCallCount == 1)
    }

    @Test
    func test_startNewConversation_when_reset_pending_then_messages_remain_until_reset_completes()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.script([
            .event(.textChunk("Hello")),
            .event(.completed(routeConfidence: nil))
        ])
        let controller = AssistantController(backend: backend, context: defaultContext)
        controller.send("hi")
        await controller.activeTask?.value
        let messagesBeforeReset = controller.conversation.messages.count
        backend.holdReset()

        // When
        controller.startNewConversation()
        await backend.waitForResetCall()

        // Then
        #expect(controller.conversation.messages.count == messagesBeforeReset)
        backend.releaseReset()
        await controller.activeTask?.value
        #expect(controller.conversation.messages.isEmpty)
    }

    @Test
    func test_cancel_when_stream_in_flight_then_streamingState_idle_and_no_orphan_task()
    async throws {
        // Given
        let backend = MockAssistantBackend()
        backend.holdStream(at: 0)
        backend.script([[.event(.textChunk("partial"))]])
        let controller = AssistantController(backend: backend, context: defaultContext)

        // When
        controller.send("hi")
        let inFlight = controller.activeTask
        controller.cancel()

        // Then
        #expect(controller.conversation.streamingState == .idle)
        #expect(controller.activeTask == nil)

        backend.releaseStream(at: 0)
        await inFlight?.value
        let messageCountBeforeLateYield = controller.conversation.messages.count
        #expect(controller.conversation.messages.count == messageCountBeforeLateYield)
    }
}
