import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreSearchFieldAppearanceTests {

    @Test func test_init_when_enabled_then_on_surface_content_on_surface_dim_with_primary_action() {
        // Given / When an enabled field resolves its appearance
        let sut = StoreSearchFieldAppearance(isEnabled: true)

        // Then the row is surface bright, the field surface dim, the content on-surface and the action primary
        #expect(sut.container == .storeSurfaceBright)
        #expect(sut.field == .storeSurfaceDim)
        #expect(sut.content == .storeOnSurface)
        #expect(sut.placeholder == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.action == .storePrimary)
    }

    @Test func test_init_when_disabled_then_keeps_fills_and_dims_content_and_action() {
        // Given / When a disabled field resolves its appearance
        let sut = StoreSearchFieldAppearance(isEnabled: false)

        // Then the fills are unchanged and the content and action follow the state-layer rule
        #expect(sut.container == .storeSurfaceBright)
        #expect(sut.field == .storeSurfaceDim)
        #expect(sut.content == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.placeholder == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.action == .storeStateLayerOnSurfaceOpacity24)
    }
}

@Suite struct StoreSearchFieldActionTests {

    @Test func test_init_when_only_title_then_enabled_by_default() {
        // Given / When an action is created with a title and a handler
        let sut = StoreSearchFieldAction("Cancel") {}

        // Then it keeps the title and is enabled
        #expect(sut.title == "Cancel")
        #expect(sut.isEnabled)
    }

    @Test func test_action_when_tapped_then_runs_the_handler() {
        // Given an action whose handler counts its calls
        var calls = 0
        let sut = StoreSearchFieldAction("Cancel", isEnabled: false) { calls += 1 }

        // When the handler runs
        sut.action()

        // Then it was called once and the disabled flag is preserved
        #expect(calls == 1)
        #expect(sut.isEnabled == false)
    }
}

@Suite struct StoreSearchFieldSizeTests {

    @Test func test_searchFieldHeight_when_read_then_matches_the_design() {
        // Given / When the field height token is read
        let sut = StoreSize.searchFieldHeight

        // Then it is the design's 40 pt field inside the 64 pt row (p4 above and below)
        #expect(sut == 40)
        #expect(sut + StorePadding.p4 * 2 == 64)
    }
}

@Suite struct StoreSearchFieldScalingTests {

    @Test func test_maximumDynamicTypeSize_when_read_then_matches_the_top_app_bar_cap() {
        // Given / When the field's Dynamic Type cap is read
        let sut = StoreSearchFieldScaling.maximumDynamicTypeSize

        // Then it stops where the top app bar stops, so both components grow in step
        #expect(sut == .accessibility2)
        #expect(sut == StoreTopAppBarScaling.maximumDynamicTypeSize)
    }
}
