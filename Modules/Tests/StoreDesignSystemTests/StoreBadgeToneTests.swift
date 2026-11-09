import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreBadgeToneTests {

    @Test func test_custom_when_colors_are_provided_then_uses_custom_appearance() {
        // Given
        let background = Color.storePrimaryContainer
        let foreground = Color.storeOnPrimaryContainer
        let border = Color.storeOutline

        // When
        let sut = StoreBadgeTone.custom(
            background: background,
            foreground: foreground,
            border: border
        ).appearance

        // Then
        #expect(sut.background == background)
        #expect(sut.foreground == foreground)
        #expect(sut.border == border)
    }
}
