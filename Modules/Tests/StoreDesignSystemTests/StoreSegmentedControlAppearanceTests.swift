import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreSegmentedControlAppearanceTests {

    @Test func test_init_when_enabled_then_uses_android_segmented_control_roles() {
        // Given / When an enabled segmented control resolves its appearance
        let sut = StoreSegmentedControlAppearance(isEnabled: true)

        // Then its track, selected pill, and labels use the matching Android design-system roles
        #expect(sut.track == .storeSecondaryContainer)
        #expect(sut.selectedContainer == .storeSurfaceBright)
        #expect(sut.selectedText == .storeOnSurface)
        #expect(sut.unselectedText == .storeOnPrimaryContainer)
    }

    @Test func test_init_when_disabled_then_uses_state_layer_roles() {
        // Given / When a disabled segmented control resolves its appearance
        let sut = StoreSegmentedControlAppearance(isEnabled: false)

        // Then the track, selected pill, and labels use the disabled state layers
        #expect(sut.track == .storeStateLayerOnSurfaceOpacity08)
        #expect(sut.selectedContainer == .storeStateLayerOnSurfaceOpacity16)
        #expect(sut.selectedText == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.unselectedText == .storeStateLayerOnSurfaceOpacity24)
    }
}
