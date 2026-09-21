import SwiftUI
import Testing
@testable import PointOfSale

struct POSFlowButtonsViewTests {
    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_compact_then_returns_true() {
        // Given
        let sizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == true)
    }

    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_regular_then_returns_false() {
        // Given
        let sizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == false)
    }

    @Test func test_usesStackedLayout_when_horizontalSizeClass_is_nil_then_returns_false() {
        // Given
        let sizeClass: UserInterfaceSizeClass? = nil

        // When
        let result = POSFlowButtonsView.usesStackedLayout(horizontalSizeClass: sizeClass)

        // Then
        #expect(result == false)
    }
}
