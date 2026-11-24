import Testing
@testable import PointOfSale

struct POSSearchViewHelperTests {
    @Test func dismissesKeyboardOnResultSelection_when_layout_is_compact_then_returns_true() {
        // When
        let result = POSSearchViewHelper.dismissesKeyboardOnResultSelection(isCompactLayout: true)

        // Then
        #expect(result == true)
    }

    @Test func dismissesKeyboardOnResultSelection_when_layout_is_regular_then_returns_false() {
        // When
        let result = POSSearchViewHelper.dismissesKeyboardOnResultSelection(isCompactLayout: false)

        // Then
        #expect(result == false)
    }
}
