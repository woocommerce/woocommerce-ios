import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSwipeBackVetoGestureRecognizerDelegateTests {
    @Test func test_gesture_when_secondary_screen_blocks_navigation_then_begins_to_consume_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoGestureRecognizerDelegate(shouldPopOnSwipeBack: { false })

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(UIGestureRecognizer())

        // Then
        #expect(shouldBegin)
    }

    @Test func test_gesture_when_secondary_screen_allows_navigation_then_fails_for_native_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoGestureRecognizerDelegate(shouldPopOnSwipeBack: { true })

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(UIGestureRecognizer())

        // Then
        #expect(shouldBegin == false)
    }
}
