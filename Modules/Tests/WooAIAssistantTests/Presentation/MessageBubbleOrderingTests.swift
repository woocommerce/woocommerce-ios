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
    func test_orderedSegments_when_multiple_analytics_results_then_each_renders_in_emit_order() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let textID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .toolResult(id: firstID,
                        toolCallID: "call_1",
                        toolName: "analytics_revenue",
                        payload: .object(["after": .string("2026-04-07"), "before": .string("2026-04-07")])),
            .toolResult(id: secondID,
                        toolCallID: "call_2",
                        toolName: "analytics_revenue",
                        payload: .object(["after": .string("2026-05-01"), "before": .string("2026-05-01")])),
            .text(id: textID, content: "May 1 outperformed April 7.")
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstID, secondID, textID])
    }

    @Test
    func test_orderedSegments_when_text_emitted_before_show_cards_cardRender_then_text_renders_first() {
        // Given
        let textID = UUID()
        let cardID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .text(id: textID, content: "Here is the order:"),
            .cardRender(id: cardID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(7)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, cardID])
    }

    @Test
    func test_orderedSegments_when_show_cards_cardRender_emitted_before_text_then_text_renders_first_and_cards_after() {
        // Given
        let firstCardID = UUID()
        let secondCardID = UUID()
        let textID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstCardID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(11)])),
            .cardRender(id: secondCardID,
                        toolCallID: "call_2",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(22)])),
            .text(id: textID, content: "Here are your top items:")
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, firstCardID, secondCardID])
    }

    @Test
    func test_orderedSegments_when_non_show_cards_cardRender_emitted_before_text_then_natural_order_preserved() {
        // Given
        let cardID = UUID()
        let textID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: cardID,
                        toolCallID: "call_1",
                        toolName: "orders_get.order",
                        payload: .object(["id": .int(99)])),
            .text(id: textID, content: "Order details below.")
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [cardID, textID])
    }

    @Test
    func test_orderedSegments_when_message_is_streaming_then_cardRender_segments_are_hidden() {
        // Given
        let textID = UUID()
        let firstCardID = UUID()
        let secondCardID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .text(id: textID, content: "Here are your last 5 orders:"),
            .cardRender(id: firstCardID,
                        toolCallID: "call_1",
                        toolName: "orders_list.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: secondCardID,
                        toolCallID: "call_2",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(2)]))
        ], isStreaming: true)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID])
    }

    @Test
    func test_orderedSegments_when_message_completes_streaming_then_cardRender_segments_appear() {
        // Given
        let textID = UUID()
        let firstCardID = UUID()
        let secondCardID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .text(id: textID, content: "Here are your last 5 orders:"),
            .cardRender(id: firstCardID,
                        toolCallID: "call_1",
                        toolName: "orders_list.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: secondCardID,
                        toolCallID: "call_2",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(2)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, firstCardID, secondCardID])
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
