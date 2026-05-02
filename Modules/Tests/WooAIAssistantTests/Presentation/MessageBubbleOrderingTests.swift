import Foundation
import Testing
@testable import WooAIAssistant

struct MessageBubbleOrderingTests {

    @Test
    func test_orderedSegments_when_confirmation_emitted_before_cardRender_then_confirmation_renders_first() {
        // Given
        let textID = UUID()
        let confirmationID = UUID()
        let proposalID = UUID()
        let cardID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .text(id: textID, content: "Updating now."),
            .confirmation(id: confirmationID,
                          proposalID: proposalID,
                          toolName: "orders_update",
                          preview: "Set order #1 to completed",
                          status: .confirmed),
            .cardRender(id: cardID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, confirmationID, cardID])
    }

    @Test
    func test_orderedSegments_when_cardRender_then_confirmation_then_renders_in_emit_order() {
        // Given
        let cardID = UUID()
        let confirmationID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: cardID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(2)])),
            .confirmation(id: confirmationID,
                          proposalID: UUID(),
                          toolName: "orders_update",
                          preview: "Set order #2 to processing",
                          status: .pending)
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [cardID, confirmationID])
    }

    @Test
    func test_orderedSegments_when_multiple_toolCalls_then_only_last_pill_is_kept_in_place() {
        // Given
        let firstCallID = UUID()
        let textID = UUID()
        let lastCallID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .toolCall(id: firstCallID,
                      toolCallID: "c1",
                      toolName: "orders_list",
                      argumentsPreview: nil,
                      status: .completed(summary: nil)),
            .text(id: textID, content: "Looking up..."),
            .toolCall(id: lastCallID,
                      toolCallID: "c2",
                      toolName: "orders_get",
                      argumentsPreview: nil,
                      status: .running)
        ], isStreaming: true)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, lastCallID])
    }
}
