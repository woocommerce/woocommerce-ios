import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantCardTapTelemetryTests {

    private let context = AssistantTelemetryContext(conversationID: "c",
                                                    requestID: "r",
                                                    messageID: "m")

    @Test
    func test_recordTap_when_context_found_then_emits_cardTapped_with_bounded_families() throws {
        // Given
        let tracker = RecordingAssistantTelemetryTracker()
        let messageID = UUID()
        let savedContext = context
        let dispatcher = AssistantCardTelemetryDispatcher(tracker: tracker,
                                                          contextLookup: { id in
                                                              id == messageID ? savedContext : nil
                                                          })

        // When
        dispatcher.recordTap(messageID: messageID,
                             cardFamily: .order,
                             actionFamily: .openOrder)

        // Then
        try #require(tracker.events.count == 1)
        if case .cardTapped(let ctx, let cardFamily, let actionFamily) = tracker.events[0] {
            #expect(ctx == savedContext)
            #expect(cardFamily == .order)
            #expect(actionFamily == .openOrder)
        } else {
            Issue.record("expected cardTapped event")
        }
    }

    @Test
    func test_recordTap_when_messageID_nil_then_skips_emission() {
        // Given
        let tracker = RecordingAssistantTelemetryTracker()
        let dispatcher = AssistantCardTelemetryDispatcher(tracker: tracker,
                                                          contextLookup: { _ in self.context })

        // When
        dispatcher.recordTap(messageID: nil,
                             cardFamily: .product,
                             actionFamily: .openProduct)

        // Then
        #expect(tracker.events.isEmpty)
    }

    @Test
    func test_recordTap_when_context_lookup_misses_then_skips_emission() {
        // Given
        let tracker = RecordingAssistantTelemetryTracker()
        let dispatcher = AssistantCardTelemetryDispatcher(tracker: tracker,
                                                          contextLookup: { _ in nil })

        // When
        dispatcher.recordTap(messageID: UUID(),
                             cardFamily: .order,
                             actionFamily: .openOrder)

        // Then
        #expect(tracker.events.isEmpty)
    }

    @Test
    func test_conversation_telemetryContext_lookup_when_message_recorded_then_returns_context() {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        let recorded = AssistantTelemetryContext(conversationID: "conv-1",
                                                 requestID: "req-1",
                                                 messageID: messageID.uuidString)
        conversation.recordTelemetryContext(recorded, for: messageID)

        // When
        let resolved = conversation.telemetryContext(for: messageID)

        // Then
        #expect(resolved == recorded)
    }

    @Test
    func test_conversation_reset_when_called_then_clears_telemetry_context_map() {
        // Given
        let conversation = AssistantConversation()
        let messageID = conversation.beginAssistantMessage()
        let recorded = AssistantTelemetryContext(conversationID: "conv-1",
                                                 requestID: "req-1",
                                                 messageID: messageID.uuidString)
        conversation.recordTelemetryContext(recorded, for: messageID)

        // When
        conversation.reset()

        // Then
        #expect(conversation.telemetryContext(for: messageID) == nil)
    }
}
