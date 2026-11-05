import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreSegmentedControlAppearanceTests {

    @Test func test_init_when_enabled_then_uses_enabled_roles() {
        // Given
        let isEnabled = true

        // When
        let sut = StoreSegmentedControlAppearance(isEnabled: isEnabled)

        // Then
        #expect(sut.track == .storeSecondaryContainer)
        #expect(sut.selectedContainer == .storeSurfaceBright)
        #expect(sut.selectedText == .storeOnSurface)
        #expect(sut.unselectedText == .storeOnPrimaryContainer)
    }

    @Test func test_init_when_disabled_then_uses_state_layer_roles() {
        // Given
        let isEnabled = false

        // When
        let sut = StoreSegmentedControlAppearance(isEnabled: isEnabled)

        // Then
        #expect(sut.track == .storeStateLayerOnSurfaceOpacity08)
        #expect(sut.selectedContainer == .storeStateLayerOnSurfaceOpacity16)
        #expect(sut.selectedText == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.unselectedText == .storeStateLayerOnSurfaceOpacity24)
    }
}
