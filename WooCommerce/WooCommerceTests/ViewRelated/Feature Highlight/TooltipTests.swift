import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct TooltipTests {
    private let longMessage = String(repeating: "A long tooltip message that needs wrapping. ", count: 6)

    @Test(arguments: [320, 466, 669, 951] as [CGFloat])
    func test_size_when_message_is_long_then_width_stays_within_the_container_margins(containerWidth: CGFloat) {
        // Given
        let sut = Tooltip(containerWidth: containerWidth)
        sut.title = "Title"
        sut.message = longMessage

        // When
        let size = sut.size()

        // Then
        #expect(size.width <= containerWidth - 32)
    }

    @Test func test_size_when_container_is_narrower_then_tooltip_is_narrower_and_taller() {
        // Given
        let narrow = Tooltip(containerWidth: 466)
        let wide = Tooltip(containerWidth: 951)
        for tooltip in [narrow, wide] {
            tooltip.title = "Title"
            tooltip.message = longMessage
        }

        // When
        let narrowSize = narrow.size()
        let wideSize = wide.size()

        // Then
        #expect(narrowSize.width < wideSize.width)
        #expect(narrowSize.height > wideSize.height)
    }

    @Test func test_copy_when_given_a_container_width_then_content_is_kept_and_width_is_updated() {
        // Given
        let sut = Tooltip(containerWidth: 951)
        sut.title = "Title"
        sut.message = "Message"
        sut.primaryButtonTitle = "Got it"

        // When
        let copy = sut.copy(containerWidth: 466)

        // Then
        #expect(copy.containerWidth == 466)
        #expect(copy.title == "Title")
        #expect(copy.message == "Message")
        #expect(copy.primaryButtonTitle == "Got it")
    }
}
