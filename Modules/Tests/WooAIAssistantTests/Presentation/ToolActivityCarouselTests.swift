import Foundation
import Testing
@testable import WooAIAssistant

struct ToolActivityCarouselTests {

    @Test
    func test_displayed_when_snapshots_empty_then_returns_nil() {
        // Given
        let snapshots: [ToolCallSnapshot] = []

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: nil, hasSettled: true)

        // Then
        #expect(result == nil)
    }

    @Test
    func test_displayed_when_single_running_then_returns_that_snapshot_as_running() {
        // Given
        let only = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .running)
        let snapshots = [only]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: only.id, hasSettled: true)

        // Then
        #expect(result?.id == only.id)
        #expect(result?.isRunning == true)
    }

    @Test
    func test_displayed_when_displayedID_points_at_running_then_returns_it() {
        // Given
        let first = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .running)
        let second = ToolCallSnapshot(id: UUID(), toolName: "products_list", status: .running)
        let snapshots = [first, second]

        // When
        let resultFirst = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: first.id, hasSettled: true)
        let resultSecond = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: second.id, hasSettled: true)

        // Then
        #expect(resultFirst?.id == first.id)
        #expect(resultSecond?.id == second.id)
    }

    @Test
    func test_displayed_when_displayedID_points_at_completed_but_others_are_running_then_pinned_is_forced_to_running() {
        // Given
        let completed = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .completed(summary: nil))
        let running = ToolCallSnapshot(id: UUID(), toolName: "products_list", status: .running)
        let snapshots = [completed, running]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: completed.id, hasSettled: true)

        // Then
        #expect(result?.id == completed.id)
        #expect(result?.isRunning == true)
    }

    @Test
    func test_displayed_when_displayedID_is_nil_but_some_running_then_falls_back_to_first_running() {
        // Given
        let completed = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .completed(summary: nil))
        let running = ToolCallSnapshot(id: UUID(), toolName: "products_list", status: .running)
        let snapshots = [completed, running]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: nil, hasSettled: true)

        // Then
        #expect(result?.id == running.id)
        #expect(result?.isRunning == true)
    }

    @Test
    func test_displayed_when_all_completed_then_returns_last_snapshot_with_real_status() {
        // Given
        let first = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .completed(summary: nil))
        let last = ToolCallSnapshot(id: UUID(), toolName: "analytics_revenue", status: .completed(summary: "ok"))
        let snapshots = [first, last]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: first.id, hasSettled: true)

        // Then
        #expect(result?.id == last.id)
        #expect(result?.isRunning == false)
    }

    @Test
    func test_displayed_when_all_failed_then_returns_last_snapshot_with_real_status() {
        // Given
        let first = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .failed(message: "oops"))
        let last = ToolCallSnapshot(id: UUID(), toolName: "products_list", status: .failed(message: "boom"))
        let snapshots = [first, last]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots, displayedID: nil, hasSettled: true)

        // Then
        #expect(result?.id == last.id)
        if case .failed = result?.status {
            // Then status is preserved as failed
        } else {
            Issue.record("Expected failed status")
        }
    }

    @Test
    func test_displayed_when_all_completed_but_not_yet_settled_then_still_shows_running() {
        // Given
        let completed = ToolCallSnapshot(id: UUID(), toolName: "orders_list", status: .completed(summary: nil))
        let snapshots = [completed]

        // When
        let result = ToolActivityCarousel.displayed(snapshots: snapshots,
                                                    displayedID: completed.id,
                                                    hasSettled: false)

        // Then
        #expect(result?.id == completed.id)
        #expect(result?.isRunning == true)
    }
}
