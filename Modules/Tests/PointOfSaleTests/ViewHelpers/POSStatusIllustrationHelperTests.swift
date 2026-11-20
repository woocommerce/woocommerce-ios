import Testing
@testable import PointOfSale

struct POSStatusIllustrationHelperTests {
    @Test func test_illustrationSize_when_full_size_keyboard_is_visible_then_returns_three_quarters_of_the_regular_size() {
        // When
        let compactSize = POSStatusIllustrationHelper.illustrationSize(isFullSizeKeyboardVisible: true)
        let regularSize = POSStatusIllustrationHelper.illustrationSize(isFullSizeKeyboardVisible: false)

        // Then
        #expect(regularSize == 88)
        #expect(compactSize == 66)
    }

    @Test func test_errorMarkSize_when_full_size_keyboard_is_visible_then_returns_largeCompact() {
        // When
        let result = POSStatusIllustrationHelper.errorMarkSize(isFullSizeKeyboardVisible: true)

        // Then
        #expect(result == .largeCompact)
        #expect(result.dimension == 60)
    }

    @Test func test_errorMarkSize_when_full_size_keyboard_is_hidden_then_returns_large() {
        // When
        let result = POSStatusIllustrationHelper.errorMarkSize(isFullSizeKeyboardVisible: false)

        // Then
        #expect(result == .large)
    }
}
