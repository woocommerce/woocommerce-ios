import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct RESTDateBoundsTests {
    @Test
    func test_previous_period_bounds_when_inputs_are_seven_days_then_previous_window_is_immediately_preceding_seven_days() {
        // Given
        let after = "2026-05-01"
        let before = "2026-05-07"

        // When
        let result = RESTDateBounds.previousPeriodBounds(after: after, before: before)

        // Then
        #expect(result?.after == "2026-04-24")
        #expect(result?.before == "2026-04-30")
    }

    @Test
    func test_previous_period_bounds_when_inputs_are_single_day_then_previous_window_is_the_day_before() {
        // Given
        let after = "2026-05-15"
        let before = "2026-05-15"

        // When
        let result = RESTDateBounds.previousPeriodBounds(after: after, before: before)

        // Then
        #expect(result?.after == "2026-05-14")
        #expect(result?.before == "2026-05-14")
    }

    @Test
    func test_previous_period_bounds_when_inputs_invalid_then_returns_nil() {
        // Given / When
        let result = RESTDateBounds.previousPeriodBounds(after: "not-a-date", before: "2026-05-07")

        // Then
        #expect(result == nil)
    }
}
