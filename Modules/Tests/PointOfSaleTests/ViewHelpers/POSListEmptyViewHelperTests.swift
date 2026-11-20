import Testing
@testable import PointOfSale

struct POSListEmptyViewHelperTests {
    @Test func test_showsIcon_when_keyboard_is_hidden_then_returns_true() {
        // When
        let result = POSListEmptyViewHelper.showsIcon(isAccessibilitySize: false,
                                                      isFullSizeKeyboardVisible: false,
                                                      showsIconAboveKeyboardOnPhone: false,
                                                      isCompactWidthAndRegularHeight: false)

        // Then
        #expect(result == true)
    }

    @Test func test_showsIcon_when_full_size_keyboard_is_visible_and_not_opted_in_then_returns_false() {
        // When
        let result = POSListEmptyViewHelper.showsIcon(isAccessibilitySize: false,
                                                      isFullSizeKeyboardVisible: true,
                                                      showsIconAboveKeyboardOnPhone: false,
                                                      isCompactWidthAndRegularHeight: true)

        // Then
        #expect(result == false)
    }

    @Test func test_showsIcon_when_full_size_keyboard_is_visible_and_opted_in_on_compact_width_and_regular_height_then_returns_true() {
        // When
        let result = POSListEmptyViewHelper.showsIcon(isAccessibilitySize: false,
                                                      isFullSizeKeyboardVisible: true,
                                                      showsIconAboveKeyboardOnPhone: true,
                                                      isCompactWidthAndRegularHeight: true)

        // Then
        #expect(result == true)
    }

    @Test func test_showsIcon_when_full_size_keyboard_is_visible_and_opted_in_outside_compact_width_and_regular_height_then_returns_false() {
        // When
        let result = POSListEmptyViewHelper.showsIcon(isAccessibilitySize: false,
                                                      isFullSizeKeyboardVisible: true,
                                                      showsIconAboveKeyboardOnPhone: true,
                                                      isCompactWidthAndRegularHeight: false)

        // Then
        #expect(result == false)
    }

    @Test(arguments: [false, true])
    func test_showsIcon_when_accessibility_size_then_returns_false(isFullSizeKeyboardVisible: Bool) {
        // When
        let result = POSListEmptyViewHelper.showsIcon(isAccessibilitySize: true,
                                                      isFullSizeKeyboardVisible: isFullSizeKeyboardVisible,
                                                      showsIconAboveKeyboardOnPhone: true,
                                                      isCompactWidthAndRegularHeight: true)

        // Then
        #expect(result == false)
    }
}
