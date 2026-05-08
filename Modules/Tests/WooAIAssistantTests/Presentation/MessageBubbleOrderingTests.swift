import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
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
                          preview: ConfirmationPreview(summary: .raw("Set order #1 to completed")),
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
                          preview: ConfirmationPreview(summary: .raw("Set order #2 to processing")),
                          status: .pending)
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [cardID, confirmationID])
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
    func test_orderedSegments_when_non_show_cards_cardRender_emitted_before_text_then_text_renders_first_and_card_after() {
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
        #expect(ids == [textID, cardID])
    }

    @Test
    func test_orderedSegments_when_message_is_streaming_then_cardRender_segments_are_hidden_until_completion() {
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
    func test_orderedSegments_when_two_cardRenders_for_same_family_and_id_then_keeps_first() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstID,
                        toolCallID: "call_a:card:0:order:3692",
                        toolName: "orders_get.order",
                        payload: .object(["id": .int(3692)])),
            .cardRender(id: secondID,
                        toolCallID: "call_b:card:0:order:3692",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(3692), "customer_name": .string("Anil")]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstID])
    }

    @Test
    func test_orderedSegments_when_two_cardRenders_for_same_family_different_ids_then_keeps_both() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstID,
                        toolCallID: "call_a:card:0:order:1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: secondID,
                        toolCallID: "call_a:card:1:order:2",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(2)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstID, secondID])
    }

    @Test
    func test_orderedSegments_when_two_cardRenders_for_different_families_same_id_then_keeps_both() {
        // Given
        let orderID = UUID()
        let productID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: orderID,
                        toolCallID: "call_a:card:0:order:7",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(7)])),
            .cardRender(id: productID,
                        toolCallID: "call_b:card:0:product:7",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(7)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [orderID, productID])
    }

    @Test
    func test_orderedSegments_when_three_cardRenders_for_same_entity_then_keeps_only_first() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let thirdID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstID,
                        toolCallID: "call_a:card:0:order:42",
                        toolName: "orders_get.order",
                        payload: .object(["id": .int(42)])),
            .cardRender(id: secondID,
                        toolCallID: "call_b:card:0:order:42",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(42)])),
            .cardRender(id: thirdID,
                        toolCallID: "call_c:card:0:order:42",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(42)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstID])
    }

    @Test
    func test_orderedSegments_when_synthetic_ids_contain_colons_then_dedupes_by_full_id() {
        // Given
        let firstRevenueID = UUID()
        let secondRevenueID = UUID()
        let ordersID = UUID()
        let revenueCardID = "analytics_revenue:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let ordersCardID = "analytics_orders:after:2026-04-01:before:2026-04-30:interval:day:currency:none"
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstRevenueID,
                        toolCallID: "call_a:card:0:analytics_stats:\(revenueCardID)",
                        toolName: "analytics_revenue",
                        payload: .object(["id": .string(revenueCardID)])),
            .cardRender(id: secondRevenueID,
                        toolCallID: "call_b:card:0:analytics_stats:\(revenueCardID)",
                        toolName: "analytics_revenue",
                        payload: .object(["id": .string(revenueCardID)])),
            .cardRender(id: ordersID,
                        toolCallID: "call_c:card:0:analytics_stats:\(ordersCardID)",
                        toolName: "analytics_orders",
                        payload: .object(["id": .string(ordersCardID)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstRevenueID, ordersID])
    }

    @Test
    func test_orderedSegments_when_no_cardRender_segments_then_passes_through_unchanged() {
        // Given
        let textID = UUID()
        let confirmationID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .text(id: textID, content: "Working on it."),
            .confirmation(id: confirmationID,
                          proposalID: UUID(),
                          toolName: "orders_update",
                          preview: ConfirmationPreview(summary: .raw("Set order #1 to completed")),
                          status: .pending)
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID, confirmationID])
    }

    @Test
    func test_orderedSegments_when_cardRender_toolCallID_is_not_synthetic_then_skips_dedupe() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .cardRender(id: firstID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: secondID,
                        toolCallID: "call_2",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)]))
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [firstID, secondID])
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

    @Test
    func test_orderedSegments_when_only_channel_is_toolResult_then_no_card_renders() {
        // Given
        let resultID = UUID()
        let textID = UUID()
        let message = ChatMessage(role: .assistant, segments: [
            .toolResult(id: resultID,
                        toolCallID: "call_1",
                        toolName: "orders_list",
                        payload: .object(["count": .int(3),
                                          "ids": .array([.int(1), .int(2), .int(3)])])),
            .text(id: textID, content: "Three orders today.")
        ], isStreaming: false)

        // When
        let bubble = MessageBubble(message: message)
        let ids = bubble.orderedSegments.map(\.id)

        // Then
        #expect(ids == [textID])
    }
}
