import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct MessageListLoadingIndicatorTests {

    @Test
    func test_loadingIndicator_when_awaitingConfirmation_then_isHidden() {
        // Given
        let pendingConfirmation = ChatMessage(role: .assistant,
                                              segments: [.confirmation(id: UUID(),
                                                                       proposalID: UUID(),
                                                                       toolName: "orders_update",
                                                                       preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")),
                                                                       status: .pending)],
                                              isStreaming: true)

        // When
        let visible = MessageListView.shouldShowLoadingIndicator(messages: [pendingConfirmation],
                                                                 streamingState: .sending)

        // Then
        #expect(visible == false)
    }

    @Test
    func test_loadingIndicator_when_streamingTokens_then_isVisible() {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        conversation.setStreaming(.sending)

        // When
        let visibleAtSending = MessageListView.shouldShowLoadingIndicator(messages: conversation.messages,
                                                                          streamingState: conversation.streamingState)
        conversation.apply(.textChunk("partial "), to: messageID)
        conversation.setStreaming(.streaming)
        let visibleAtStreaming = MessageListView.shouldShowLoadingIndicator(messages: conversation.messages,
                                                                            streamingState: conversation.streamingState)

        // Then
        #expect(visibleAtSending == true)
        #expect(visibleAtStreaming == false)
    }

    @Test
    func test_loadingIndicator_when_confirmationResolved_and_loop_resumes_then_isVisible() {
        // Given
        let proposalID = UUID()
        let approvedConfirmation = ChatMessage(role: .assistant,
                                               segments: [.confirmation(id: UUID(),
                                                                        proposalID: proposalID,
                                                                        toolName: "orders_update",
                                                                        preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")),
                                                                        status: .confirmed)],
                                               isStreaming: true)

        // When
        let visible = MessageListView.shouldShowLoadingIndicator(messages: [approvedConfirmation],
                                                                 streamingState: .sending)

        // Then
        #expect(visible == true)
    }

    @Test
    func test_loadingIndicator_when_no_active_turn_then_isHidden() {
        // Given
        let completedTurn = ChatMessage(role: .assistant,
                                        segments: [.text(id: UUID(), content: "Done.")],
                                        isStreaming: false)

        // When
        let visible = MessageListView.shouldShowLoadingIndicator(messages: [completedTurn],
                                                                 streamingState: .idle)

        // Then
        #expect(visible == false)
    }

    @Test
    func test_loadingIndicator_when_declinedConfirmation_and_followUpSending_then_isVisible() {
        // Given
        let declinedConfirmation = ChatMessage(role: .assistant,
                                               segments: [.confirmation(id: UUID(),
                                                                        proposalID: UUID(),
                                                                        toolName: "orders_update",
                                                                        preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")),
                                                                        status: .cancelled)],
                                               isStreaming: true)

        // When
        let visible = MessageListView.shouldShowLoadingIndicator(messages: [declinedConfirmation],
                                                                 streamingState: .sending)

        // Then
        #expect(visible == true)
    }

    @Test
    func test_loadingIndicator_when_pendingConfirmation_in_earlier_message_then_isHidden() {
        // Given
        let earlierPending = ChatMessage(role: .assistant,
                                         segments: [.confirmation(id: UUID(),
                                                                  proposalID: UUID(),
                                                                  toolName: "orders_update",
                                                                  preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")),
                                                                  status: .pending)],
                                         isStreaming: false)
        let userFollowUp = ChatMessage(role: .user,
                                       segments: [.text(id: UUID(), content: "Cancel that")])

        // When
        let visible = MessageListView.shouldShowLoadingIndicator(messages: [earlierPending, userFollowUp],
                                                                 streamingState: .sending)

        // Then
        #expect(visible == false)
    }

    @Test
    func test_hasPendingConfirmation_when_only_resolved_segments_then_false() {
        // Given
        let resolved = ChatMessage(role: .assistant,
                                   segments: [.confirmation(id: UUID(),
                                                            proposalID: UUID(),
                                                            toolName: "orders_update",
                                                            preview: ConfirmationPreview(summary: .raw("Mark order 42 as processing")),
                                                            status: .confirmed),
                                              .confirmation(id: UUID(),
                                                            proposalID: UUID(),
                                                            toolName: "orders_update",
                                                            preview: ConfirmationPreview(summary: .raw("Mark order 43 as processing")),
                                                            status: .cancelled)])

        // When
        let pending = [resolved].hasPendingConfirmation

        // Then
        #expect(pending == false)
    }
}
