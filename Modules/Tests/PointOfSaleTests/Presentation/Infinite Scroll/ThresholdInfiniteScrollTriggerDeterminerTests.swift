import Foundation
import Testing
@testable import PointOfSale

struct ThresholdInfiniteScrollTriggerDeterminerTests {
    @Test func shouldTriggerInfiniteScroll_returns_true_when_scrollPosition_is_at_threshold() async throws {
        // Given
        let sut = ThresholdInfiniteScrollTriggerDeterminer(scrollTriggerThreshold: 0.5)

        // When
        let scrollViewHeight: CGFloat = 500
        let contentHeight: CGFloat = 1000
        let scrollPosition: CGFloat = 250 // (contentHeight - scrollViewHeight) = 500 is the scrollable height, times the threshold ratio 0.5

        let result = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: contentHeight
        )

        // Then
        #expect(result == true)
    }

    @Test func shouldTriggerInfiniteScroll_returns_false_when_scrollPosition_is_far_from_threshold() async throws {
        // Given
        let sut = ThresholdInfiniteScrollTriggerDeterminer()

        // When
        let scrollViewHeight: CGFloat = 500
        let contentHeight: CGFloat = 1000
        let scrollPosition: CGFloat = 0 // At top
        let result = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: contentHeight
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldTriggerInfiniteScroll_returns_false_when_content_height_is_less_than_scroll_view_height() async throws {
        // Given
        let sut = ThresholdInfiniteScrollTriggerDeterminer()

        // When
        let scrollViewHeight: CGFloat = 500
        let contentHeight: CGFloat = 300 // Smaller than scroll view
        let scrollPosition: CGFloat = 200
        let result = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: contentHeight
        )

        // Then
        #expect(result == false)
    }

    @Test func shouldTriggerInfiniteScroll_returns_true_when_triggered_twice_at_same_position() async throws {
        // Given
        let sut = ThresholdInfiniteScrollTriggerDeterminer()
        let scrollViewHeight: CGFloat = 500
        let contentHeight: CGFloat = 1000
        let scrollPosition = contentHeight - scrollViewHeight - 100

        // When
        // First trigger
        let firstResult = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: contentHeight
        )

        // Second attempt at same position
        let secondResult = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: contentHeight
        )

        // Then
        #expect(firstResult == true)
        #expect(secondResult == true)
    }

    @Test func shouldTriggerInfiniteScroll_returns_true_when_content_height_changes() async throws {
        // Given
        let sut = ThresholdInfiniteScrollTriggerDeterminer()
        let scrollViewHeight: CGFloat = 500
        let initialContentHeight: CGFloat = 1000
        let newContentHeight: CGFloat = 1500
        let scrollPosition = newContentHeight - scrollViewHeight - 100

        // When
        // First trigger with initial content height
        _ = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: initialContentHeight
        )

        // Second trigger with new content height
        let result = sut.shouldTriggerInfiniteScroll(
            scrollPosition: scrollPosition,
            scrollViewHeight: scrollViewHeight,
            contentHeight: newContentHeight
        )

        // Then
        #expect(result == true)
    }
}
