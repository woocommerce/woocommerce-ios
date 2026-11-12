import SwiftUI
import Testing
@testable import PointOfSale

struct POSBottomSheetContentInsetsTests {
    @Test func test_bottomSheetContentInsets_when_compact_then_uses_wide_insets_that_clear_the_grabber() {
        // Given
        let metrics = POSMetrics.compact

        // When
        let insets = metrics.bottomSheetContentInsets(horizontalSizeClass: .compact)

        // Then
        #expect(insets.leading == metrics.padding.xxLarge)
        #expect(insets.trailing == metrics.padding.xxLarge)
        #expect(insets.top == metrics.padding.xxLarge + metrics.padding.large)
        #expect(insets.bottom == metrics.padding.none)
    }

    @Test func test_bottomSheetContentInsets_when_regular_then_keeps_the_iPad_insets() {
        // Given
        let metrics = POSMetrics.regular

        // When
        let insets = metrics.bottomSheetContentInsets(horizontalSizeClass: .regular)

        // Then
        #expect(insets.leading == metrics.padding.medium)
        #expect(insets.trailing == metrics.padding.medium)
        #expect(insets.top == metrics.padding.large)
        #expect(insets.bottom == metrics.padding.none)
    }
}
