import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreTabRowAppearanceTests {

    @Test func test_init_when_enabled_then_on_surface_text_with_primary_indicator() {
        // Given / When an enabled row resolves its appearance
        let sut = StoreTabRowAppearance(isEnabled: true)

        // Then it is surface bright with on-surface text and a primary indicator
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.foreground == .storeOnSurface)
        #expect(sut.indicator == .storePrimary)
    }

    @Test func test_init_when_disabled_then_keeps_background_and_dims_text_and_indicator() {
        // Given / When a disabled row resolves its appearance
        let sut = StoreTabRowAppearance(isEnabled: false)

        // Then the background is unchanged and the text and indicator follow the state-layer rule
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.foreground == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.indicator == .storeStateLayerOnSurfaceOpacity24)
    }
}

@Suite struct StoreTabRowLayoutTests {

    @Test func test_init_when_text_only_then_content_sits_at_the_bottom_above_the_inset() {
        // Given / When a tab without an icon resolves its layout
        let sut = StoreTabRowLayout(hasIcon: false)

        // Then the label is bottom-aligned above a p5 inset (the design's p6 less the line box's descent), with no top inset
        #expect(sut.contentAlignment == .bottom)
        #expect(sut.topInset == StorePadding.p0)
        #expect(sut.bottomInset == StorePadding.p5)
    }

    @Test func test_init_when_icon_then_content_sits_at_the_top_between_its_insets() {
        // Given / When a tab with an icon resolves its layout
        let sut = StoreTabRowLayout(hasIcon: true)

        // Then the icon and label are top-aligned with a p1 inset above and a p3 inset below
        #expect(sut.contentAlignment == .top)
        #expect(sut.topInset == StorePadding.p1)
        #expect(sut.bottomInset == StorePadding.p3)
    }
}
