import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct MessageSegmentTests {
    @Test
    func test_messageSegment_id_returns_segment_id_for_each_case() {
        // Given
        let textID = UUID()
        let toolCallID = UUID()
        let toolResultID = UUID()
        let cardRenderID = UUID()
        let confirmationID = UUID()

        let segments: [MessageSegment] = [
            .text(id: textID, content: "hi"),
            .toolCall(id: toolCallID,
                      toolCallID: "call_1",
                      toolName: "orders_list",
                      argumentsPreview: nil,
                      status: .running),
            .toolResult(id: toolResultID,
                        toolCallID: "call_1",
                        toolName: "orders_list",
                        payload: .object(["count": .int(0)])),
            .cardRender(id: cardRenderID,
                        toolCallID: "call_1",
                        toolName: "show_cards",
                        payload: .object(["id": .int(1)])),
            .confirmation(id: confirmationID,
                          proposalID: UUID(),
                          toolName: "orders_update",
                          preview: ConfirmationPreview(summary: .raw("Mark order #1 completed")),
                          status: .pending)
        ]

        // When / Then
        #expect(segments.map(\.id) == [textID, toolCallID, toolResultID, cardRenderID, confirmationID])
    }

    @Test
    func test_messageSegment_when_two_text_segments_have_same_payload_then_equal() {
        // Given
        let id = UUID()
        let lhs: MessageSegment = .text(id: id, content: "hello")
        let rhs: MessageSegment = .text(id: id, content: "hello")

        // When / Then
        #expect(lhs == rhs)
    }

    @Test
    func test_messageSegment_when_text_segments_differ_in_content_then_not_equal() {
        // Given
        let id = UUID()
        let lhs: MessageSegment = .text(id: id, content: "hello")
        let rhs: MessageSegment = .text(id: id, content: "world")

        // When / Then
        #expect(lhs != rhs)
    }

    @Test
    func test_toolCallStatus_when_completed_with_summary_then_carries_summary() {
        // Given / When
        let status: ToolCallStatus = .completed(summary: "1 order found")

        // Then
        guard case .completed(let summary) = status else {
            Issue.record("expected .completed, got \(status)")
            return
        }
        #expect(summary == "1 order found")
    }

    @Test
    func test_confirmationStatus_when_pending_then_distinct_from_resolved_states() {
        #expect(ConfirmationStatus.pending != .confirmed)
        #expect(ConfirmationStatus.pending != .cancelled)
        #expect(ConfirmationStatus.confirmed != .cancelled)
    }
}
