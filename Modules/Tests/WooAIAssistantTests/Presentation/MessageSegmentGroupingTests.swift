import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct MessageSegmentGroupingTests {

    @Test
    func test_segments_when_single_cardRender_then_renders_single_card() {
        // Given
        let textID = UUID()
        let cardID = UUID()
        let segments: [MessageSegment] = [
            .text(id: textID, content: "Here is the order:"),
            .cardRender(id: cardID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 2)
        #expect(groups[0] == .solo(segments[0]))
        #expect(groups[1] == .solo(segments[1]))
    }

    @Test
    func test_segments_when_consecutive_cardRender_runs_of_same_family_then_renders_one_list_card() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let thirdID = UUID()
        let segments: [MessageSegment] = [
            .cardRender(id: firstID,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: secondID,
                        toolCallID: "call_2",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(2)])),
            .cardRender(id: thirdID,
                        toolCallID: "call_3",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(3)]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 1)
        if case .cardRun(let family, let runSegments) = groups[0] {
            #expect(family == .order)
            #expect(runSegments.map(\.id) == [firstID, secondID, thirdID])
        } else {
            Issue.record("Expected a single .cardRun group, got \(groups)")
        }
    }

    @Test
    func test_segments_when_cardRender_runs_of_mixed_families_then_renders_one_list_card_per_family() {
        // Given
        let order1 = UUID()
        let order2 = UUID()
        let product1 = UUID()
        let product2 = UUID()
        let segments: [MessageSegment] = [
            .cardRender(id: order1,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(10)])),
            .cardRender(id: order2,
                        toolCallID: "call_2",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(11)])),
            .cardRender(id: product1,
                        toolCallID: "call_3",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(20)])),
            .cardRender(id: product2,
                        toolCallID: "call_4",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(21)]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 2)
        if case .cardRun(let family, let runSegments) = groups[0] {
            #expect(family == .order)
            #expect(runSegments.map(\.id) == [order1, order2])
        } else {
            Issue.record("Expected first group to be an order .cardRun, got \(groups)")
        }
        if case .cardRun(let family, let runSegments) = groups[1] {
            #expect(family == .product)
            #expect(runSegments.map(\.id) == [product1, product2])
        } else {
            Issue.record("Expected second group to be a product .cardRun, got \(groups)")
        }
    }

    @Test
    func test_segments_when_text_separates_cardRender_runs_then_each_run_renders_independently() {
        // Given
        let textBefore = UUID()
        let order1 = UUID()
        let order2 = UUID()
        let textBetween = UUID()
        let product1 = UUID()
        let product2 = UUID()
        let segments: [MessageSegment] = [
            .text(id: textBefore, content: "Top orders:"),
            .cardRender(id: order1,
                        toolCallID: "call_1",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(1)])),
            .cardRender(id: order2,
                        toolCallID: "call_2",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(2)])),
            .text(id: textBetween, content: "And these products:"),
            .cardRender(id: product1,
                        toolCallID: "call_3",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(3)])),
            .cardRender(id: product2,
                        toolCallID: "call_4",
                        toolName: "show_cards.product",
                        payload: .object(["id": .int(4)]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 4)
        #expect(groups[0] == .solo(segments[0]))
        if case .cardRun(let family, let runSegments) = groups[1] {
            #expect(family == .order)
            #expect(runSegments.count == 2)
        } else {
            Issue.record("Expected order .cardRun at index 1")
        }
        #expect(groups[2] == .solo(segments[3]))
        if case .cardRun(let family, let runSegments) = groups[3] {
            #expect(family == .product)
            #expect(runSegments.count == 2)
        } else {
            Issue.record("Expected product .cardRun at index 3")
        }
    }

    @Test
    func test_segments_when_cardRender_run_exceeds_visible_limit_then_truncates_to_limit() {
        // Given
        let total = entityCardVisibleRowLimit + 5
        let segments: [MessageSegment] = (0..<total).map { index in
            .cardRender(id: UUID(),
                        toolCallID: "call_\(index)",
                        toolName: "show_cards.order",
                        payload: .object(["id": .int(Int64(index))]))
        }

        // When
        let groups = MessageSegmentGrouping.group(segments)
        let payloads: [AnyCodableJSON] = {
            guard case .cardRun(_, let runSegments) = groups[0] else { return [] }
            return runSegments.compactMap { segment in
                if case .cardRender(_, _, _, let payload) = segment { return payload }
                return nil
            }
        }()
        let listPayload = AnyCodableJSON.object(["rows": .array(payloads)])
        let visible = EntityCardPayload.visible(EntityCardPayload.decodeOrderRows(listPayload))

        // Then
        #expect(groups.count == 1)
        #expect(payloads.count == total)
        #expect(visible.count == entityCardVisibleRowLimit)
    }

    @Test
    func test_segments_when_orders_list_toolResult_with_no_cardRender_then_renders_as_solo_toolResult() {
        // Given
        let resultID = UUID()
        let textID = UUID()
        let segments: [MessageSegment] = [
            .text(id: textID, content: "Here are your last 5 orders:"),
            .toolResult(id: resultID,
                        toolCallID: "call_1",
                        toolName: "orders_list",
                        payload: .object(["count": .int(5),
                                          "rows": .array([.object(["id": .int(1)])])]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 2)
        #expect(groups[0] == .solo(segments[0]))
        #expect(groups[1] == .solo(segments[1]))
    }

    @Test
    func test_segments_when_cardRender_runs_use_unknown_family_then_each_segment_stays_solo() {
        // Given
        let firstID = UUID()
        let secondID = UUID()
        let segments: [MessageSegment] = [
            .cardRender(id: firstID,
                        toolCallID: "call_1",
                        toolName: "settings_get",
                        payload: .object([:])),
            .cardRender(id: secondID,
                        toolCallID: "call_2",
                        toolName: "settings_get",
                        payload: .object([:]))
        ]

        // When
        let groups = MessageSegmentGrouping.group(segments)

        // Then
        #expect(groups.count == 2)
        #expect(groups[0] == .solo(segments[0]))
        #expect(groups[1] == .solo(segments[1]))
    }
}
