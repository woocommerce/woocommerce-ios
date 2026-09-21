import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct AssistantTelemetryContextTests {

    @Test
    func test_init_when_called_then_exposes_three_string_ids() {
        // Given
        let context = AssistantTelemetryContext(conversationID: "conversation",
                                                requestID: "request",
                                                messageID: "message")

        // Then
        #expect(context.conversationID == "conversation")
        #expect(context.requestID == "request")
        #expect(context.messageID == "message")
    }

    @Test
    func test_equality_when_all_ids_match_then_contexts_are_equal() {
        // Given
        let a = AssistantTelemetryContext(conversationID: "c", requestID: "r", messageID: "m")
        let b = AssistantTelemetryContext(conversationID: "c", requestID: "r", messageID: "m")

        // Then
        #expect(a == b)
    }

    @Test
    func test_equality_when_any_id_differs_then_contexts_are_unequal() {
        // Given
        let a = AssistantTelemetryContext(conversationID: "c", requestID: "r", messageID: "m")
        let b = AssistantTelemetryContext(conversationID: "c", requestID: "r2", messageID: "m")

        // Then
        #expect(a != b)
    }
}
