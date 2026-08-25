import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct ProductsSwipeBackVetoPolicyTests {
    @Test func test_policy_when_secondary_screen_blocks_navigation_then_vetoes_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoPolicy(shouldVetoSwipeBack: { true })

        // When
        let shouldVeto = sut.shouldVeto()

        // Then
        #expect(shouldVeto)
    }

    @Test func test_policy_when_secondary_screen_allows_navigation_then_fails_for_native_swipe() {
        // Given
        let sut = ProductsSwipeBackVetoPolicy(shouldVetoSwipeBack: { false })

        // When
        let shouldVeto = sut.shouldVeto()

        // Then
        #expect(shouldVeto == false)
    }
}
