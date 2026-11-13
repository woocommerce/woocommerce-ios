import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreCellAppearanceTests {

    @Test func test_init_when_enabled_then_uses_surface_roles() {
        // Given / When an enabled cell resolves its appearance
        let sut = StoreCellAppearance(isEnabled: true)

        // Then the container is surface bright with on-surface text and on-surface-variant slots
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.title == .storeOnSurface)
        #expect(sut.description == .storeOnSurfaceVariant)
        #expect(sut.slot == .storeOnSurfaceVariant)
    }

    @Test func test_init_when_disabled_then_keeps_container_and_dims_foreground() {
        // Given / When a disabled cell resolves its appearance
        let sut = StoreCellAppearance(isEnabled: false)

        // Then the container is unchanged and every foreground follows the state-layer rule
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.title == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.description == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.slot == .storeStateLayerOnSurfaceOpacity24)
    }
}
