import Foundation
import Testing
@testable import WooAIAssistant

@MainActor
struct ChatScrollControllerTests {

    @Test
    func test_isNearBottom_starts_true() {
        // Given / When
        let controller = ChatScrollController()
        // Then
        #expect(controller.isNearBottom == true)
    }

    @Test
    func test_scrollToBottom_when_handler_unset_then_no_op() {
        // Given
        let controller = ChatScrollController()
        // When / Then (must not crash)
        controller.scrollToBottom(animated: false)
    }

    @Test
    func test_scrollToBottom_when_handler_set_then_invokes_handler() {
        // Given
        let controller = ChatScrollController()
        var captured: Bool?
        controller.scrollToBottomHandler = { animated in captured = animated }
        // When
        controller.scrollToBottom(animated: true)
        // Then
        #expect(captured == true)
    }
}
