import Testing
@testable import PointOfSale

struct POSGuidedAccessGuideSlideTests {
    @Test func test_navigation_when_following_guide_then_back_retraces_steps_and_done_only_appears_at_end() throws {
        // Given
        let first = POSGuidedAccessGuideSlide.openSettings
        #expect(first.previous == nil)
        #expect(first.action == .openSettings)

        // When
        let second = try #require(first.next)
        let last = try #require(second.next)

        // Then
        #expect(second == .turnOn)
        #expect(second.action == .openSettings)
        #expect(last == .start)
        #expect(last.action == .done)
        #expect(last.next == nil)
        #expect(last.previous == second)
        #expect(second.previous == first)
    }
}
