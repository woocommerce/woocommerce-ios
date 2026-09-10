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

    @Test func test_childBehavior_when_trailing_slot_is_empty_then_combines_children() {
        // Given a static cell without trailing content / When resolving its VoiceOver grouping
        // Then the row reads as one element
        #expect(StoreCellAccessibility.childBehavior(hasTrailingContent: false) == .combine)
    }

    @Test func test_childBehavior_when_trailing_slot_has_content_then_keeps_children_reachable() {
        // Given a static cell with trailing content (which may hold a control) / When resolving its grouping
        // Then the children stay individually reachable
        #expect(StoreCellAccessibility.childBehavior(hasTrailingContent: true) == .contain)
    }
}
