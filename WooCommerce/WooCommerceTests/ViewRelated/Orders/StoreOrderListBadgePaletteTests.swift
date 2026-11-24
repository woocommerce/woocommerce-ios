import SwiftUI
import Testing
@testable import StoreDesignSystem
@testable import WooCommerce

@Suite struct StoreOrderListBadgePaletteTests {
    @Test func test_point_of_sale_tone_when_rendered_then_uses_primary_container_colors_without_border() {
        // Given
        let tone = StoreOrderListBadgePalette.pointOfSaleTone

        // When
        let appearance = tone.appearance

        // Then
        #expect(appearance.background == Color.storePrimaryContainer)
        #expect(appearance.foreground == Color.storeOnPrimaryContainer)
        #expect(appearance.border == nil)
    }
}
