import Foundation
import Testing
@testable import WooAIAssistant

struct ChatMessageTests {
    @Test
    func test_chatMessage_updateText_appends_to_trailing_text_segment() {
        // Given
        let textID = UUID()
        var message = ChatMessage(role: .assistant,
                                  segments: [.text(id: textID, content: "Hello")],
                                  isStreaming: true)

        // When
        message.updateText(appending: ", world")

        // Then
        #expect(message.segments.count == 1)
        guard case .text(let id, let content) = message.segments[0] else {
            Issue.record("expected .text, got \(message.segments[0])")
            return
        }
        #expect(id == textID)
        #expect(content == "Hello, world")
    }

    @Test
    func test_chatMessage_updateText_when_no_text_segment_then_creates_one() {
        // Given
        var message = ChatMessage(role: .assistant,
                                  segments: [.toolCall(id: UUID(),
                                                       toolCallID: "call_1",
                                                       toolName: "orders_list",
                                                       argumentsPreview: nil,
                                                       status: .running)],
                                  isStreaming: true)

        // When
        message.updateText(appending: "Looking up orders...")

        // Then
        #expect(message.segments.count == 2)
        guard case .text(_, let content) = message.segments.last else {
            Issue.record("expected trailing .text, got \(String(describing: message.segments.last))")
            return
        }
        #expect(content == "Looking up orders...")
    }

    @Test
    func test_chatMessage_updateToolCall_when_id_matches_then_status_changes() {
        // Given
        let segmentID = UUID()
        var message = ChatMessage(role: .assistant,
                                  segments: [.toolCall(id: segmentID,
                                                       toolCallID: "call_1",
                                                       toolName: "orders_list",
                                                       argumentsPreview: "{}",
                                                       status: .running)])

        // When
        message.updateToolCall(id: "call_1", to: .completed(summary: "1 order found"))

        // Then
        guard case .toolCall(let id, let toolCallID, let toolName, let args, let status) = message.segments[0] else {
            Issue.record("expected .toolCall, got \(message.segments[0])")
            return
        }
        #expect(id == segmentID)
        #expect(toolCallID == "call_1")
        #expect(toolName == "orders_list")
        #expect(args == "{}")
        #expect(status == .completed(summary: "1 order found"))
    }

    @Test
    func test_chatMessage_updateToolCall_when_id_missing_then_segments_unchanged() {
        // Given
        let original: [MessageSegment] = [.toolCall(id: UUID(),
                                                    toolCallID: "call_1",
                                                    toolName: "orders_list",
                                                    argumentsPreview: nil,
                                                    status: .running)]
        var message = ChatMessage(role: .assistant, segments: original)

        // When
        message.updateToolCall(id: "call_999", to: .completed(summary: nil))

        // Then
        #expect(message.segments == original)
    }

    @Test
    func test_chatMessage_updateConfirmation_when_pending_then_resolves_to_confirmed() {
        // Given
        let proposalID = UUID()
        var message = ChatMessage(role: .assistant,
                                  segments: [.confirmation(id: UUID(),
                                                           proposalID: proposalID,
                                                           toolName: "orders_update",
                                                           preview: "Mark order #3551 completed",
                                                           status: .pending)])

        // When
        message.updateConfirmation(proposalID: proposalID, to: .confirmed)

        // Then
        guard case .confirmation(_, _, _, _, let status) = message.segments[0] else {
            Issue.record("expected .confirmation, got \(message.segments[0])")
            return
        }
        #expect(status == .confirmed)
    }

    @Test
    func test_chatMessage_append_extends_segments_in_order() {
        // Given
        var message = ChatMessage(role: .assistant)
        let textID = UUID()
        let toolID = UUID()

        // When
        message.append(.text(id: textID, content: "hi"))
        message.append(.toolCall(id: toolID,
                                 toolCallID: "call_1",
                                 toolName: "orders_list",
                                 argumentsPreview: nil,
                                 status: .running))

        // Then
        #expect(message.segments.map(\.id) == [textID, toolID])
    }

    @Test
    func test_chatMessage_markCompleted_clears_streaming_flag() {
        // Given
        var message = ChatMessage(role: .assistant, isStreaming: true)

        // When
        message.markCompleted()

        // Then
        #expect(message.isStreaming == false)
    }

    @Test
    func test_chatMessage_updateText_when_segments_empty_then_creates_text_segment() {
        // Given
        var message = ChatMessage(role: .assistant)

        // When
        message.updateText(appending: "Hello")

        // Then
        #expect(message.segments.count == 1)
        guard case .text(_, let content) = message.segments[0] else {
            Issue.record("expected .text, got \(message.segments[0])")
            return
        }
        #expect(content == "Hello")
    }

    @Test
    func test_chatMessage_updateConfirmation_when_proposalID_missing_then_segments_unchanged() {
        // Given
        let original: [MessageSegment] = [.confirmation(id: UUID(),
                                                        proposalID: UUID(),
                                                        toolName: "orders_update",
                                                        preview: "Mark order #1 completed",
                                                        status: .pending)]
        var message = ChatMessage(role: .assistant, segments: original)

        // When
        message.updateConfirmation(proposalID: UUID(), to: .confirmed)

        // Then
        #expect(message.segments == original)
    }

    @Test
    func test_chatMessage_updateConfirmation_when_pending_then_resolves_to_cancelled() {
        // Given
        let proposalID = UUID()
        var message = ChatMessage(role: .assistant,
                                  segments: [.confirmation(id: UUID(),
                                                           proposalID: proposalID,
                                                           toolName: "orders_update",
                                                           preview: "Mark order #1 completed",
                                                           status: .pending)])

        // When
        message.updateConfirmation(proposalID: proposalID, to: .cancelled)

        // Then
        guard case .confirmation(_, _, _, _, let status) = message.segments[0] else {
            Issue.record("expected .confirmation, got \(message.segments[0])")
            return
        }
        #expect(status == .cancelled)
    }
}
