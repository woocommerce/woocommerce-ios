import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AssistantEarlyAccessNoticeCardTests {

    @Test
    func test_AssistantEarlyAccessNoticeCard_when_feedback_tapped_then_invokes_handler() {
        // Given
        var fired = false
        let card = AssistantEarlyAccessNoticeCard(onFeedbackTap: { fired = true })

        // When
        card.onFeedbackTap()

        // Then
        #expect(fired == true)
    }

    @Test
    func test_AssistantEarlyAccessNoticeCard_when_dismiss_tapped_then_invokes_handler() {
        // Given
        var fired = false
        let card = AssistantEarlyAccessNoticeCard(onFeedbackTap: {}, onDismiss: { fired = true })

        // When
        card.onDismiss?()

        // Then
        #expect(fired == true)
    }
}
