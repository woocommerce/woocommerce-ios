import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSwipeBackVetoGestureRecognizerDelegateTests {
    @Test func test_gesture_when_collapsed_and_secondary_screen_blocks_navigation_then_begins_to_consume_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoGestureRecognizerDelegate(isCollapsed: { true }, shouldPopOnSwipeBack: { false })

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(UIGestureRecognizer())

        // Then
        #expect(shouldBegin)
    }

    @Test func test_gesture_when_collapsed_and_secondary_screen_allows_navigation_then_fails_for_native_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoGestureRecognizerDelegate(isCollapsed: { true }, shouldPopOnSwipeBack: { true })

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(UIGestureRecognizer())

        // Then
        #expect(shouldBegin == false)
    }

    @Test func test_gesture_when_expanded_then_does_not_interfere_with_navigation() {
        // Given
        let sut = ProductsSwipeBackVetoGestureRecognizerDelegate(isCollapsed: { false }, shouldPopOnSwipeBack: { false })

        // When
        let shouldBegin = sut.gestureRecognizerShouldBegin(UIGestureRecognizer())

        // Then
        #expect(shouldBegin == false)
    }
}
