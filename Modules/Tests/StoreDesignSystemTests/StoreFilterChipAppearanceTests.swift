import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreFilterChipAppearanceTests {

    @Test func test_init_when_resting_and_enabled_then_outlined_on_surface_bright() {
        // Given / When a resting, enabled chip resolves its appearance
        let sut = StoreFilterChipAppearance(isSelected: false, isEnabled: true)

        // Then it is surface bright with on-surface text and the 16% on-surface border
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.foreground == .storeOnSurface)
        #expect(sut.border == .storeStateLayerOnSurfaceOpacity16)
    }

    @Test func test_init_when_selected_and_enabled_then_tonal_without_border() {
        // Given / When a selected, enabled chip resolves its appearance
        let sut = StoreFilterChipAppearance(isSelected: true, isEnabled: true)

        // Then it is the secondary container with on-secondary-container text and no border
        #expect(sut.background == .storeSecondaryContainer)
        #expect(sut.foreground == .storeOnSecondaryContainer)
        #expect(sut.border == nil)
    }

    @Test func test_init_when_resting_and_disabled_then_keeps_container_and_dims_foreground_and_border() {
        // Given / When a resting, disabled chip resolves its appearance
        let sut = StoreFilterChipAppearance(isSelected: false, isEnabled: false)

        // Then the container is unchanged and the text and border follow the state-layer rule
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.foreground == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.border == .storeStateLayerOnSurfaceOpacity10)
    }

    @Test func test_init_when_selected_and_disabled_then_dims_container_and_foreground() {
        // Given / When a selected, disabled chip resolves its appearance
        let sut = StoreFilterChipAppearance(isSelected: true, isEnabled: false)

        // Then the fill and text follow the state-layer rule and there is still no border
        #expect(sut.background == .storeStateLayerOnSurfaceOpacity08)
        #expect(sut.foreground == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.border == nil)
    }
}
