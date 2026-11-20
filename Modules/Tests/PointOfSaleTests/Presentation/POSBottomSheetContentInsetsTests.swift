import SwiftUI
import Testing
@testable import PointOfSale

struct POSBottomSheetContentInsetsTests {
    @Test func test_bottomSheetContentInsets_then_uses_wide_insets_that_clear_the_grabber() {
        // Given
        let metrics = POSMetrics.compact

        // When
        let insets = metrics.bottomSheetContentInsets

        // Then
        #expect(insets.leading == metrics.padding.xxLarge)
        #expect(insets.trailing == metrics.padding.xxLarge)
        #expect(insets.top == metrics.padding.xxLarge + metrics.padding.large)
        #expect(insets.bottom == metrics.padding.none)
    }
}
