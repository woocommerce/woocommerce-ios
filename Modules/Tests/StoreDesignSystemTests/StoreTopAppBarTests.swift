import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreTopAppBarSizeTests {

    @Test func test_small_then_uses_title_large_and_body_small_emphasized() {
        // Given / When the small bar resolves its typography
        let sut = StoreTopAppBarSize.small

        // Then it pairs the emphasized title-large title with an emphasized body-small supporting line
        #expect(sut.titleStyle == .titleLarge.emphasized)
        #expect(sut.supportingTextStyle == .bodySmall.emphasized)
    }

    @Test func test_medium_then_uses_headline_small_and_body_medium_emphasized() {
        // Given / When the medium bar resolves its typography
        let sut = StoreTopAppBarSize.medium

        // Then it pairs the emphasized headline-small title with an emphasized body-medium supporting line
        #expect(sut.titleStyle == .headlineSmall.emphasized)
        #expect(sut.supportingTextStyle == .bodyMedium.emphasized)
    }
}

@Suite struct StoreTopAppBarLayoutTests {

    @Test func test_small_when_no_navigation_then_text_starts_at_the_content_inset() {
        // Given a small section bar without a navigation control
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: false, actionCount: 1)

        // When / Then the bar has no leading inset and the text starts at p7
        #expect(sut.barLeadingInset == StorePadding.p0)
        #expect(sut.textLeadingInset == StorePadding.p7)
        #expect(sut.textTrailingInset == StorePadding.p0)
    }

    @Test func test_small_when_navigation_then_text_follows_the_control() {
        // Given a small bar with a navigation control
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 1)

        // When / Then the control sits p2 from the edge and the text s2 after it
        #expect(sut.barLeadingInset == StorePadding.p2)
        #expect(sut.textLeadingInset == StoreSpacing.s2)
    }

    @Test func test_medium_then_text_row_uses_its_own_insets() {
        // Given medium bars with and without a navigation control
        let withNavigation = StoreTopAppBarLayout(size: .medium, hasNavigation: true, actionCount: 0)
        let withoutNavigation = StoreTopAppBarLayout(size: .medium, hasNavigation: false, actionCount: 0)

        // When / Then the controls row keeps p2, and the text row is p5 / p7 leading with p5 trailing
        #expect(withNavigation.barLeadingInset == StorePadding.p2)
        #expect(withoutNavigation.barLeadingInset == StorePadding.p2)
        #expect(withNavigation.textLeadingInset == StorePadding.p5)
        #expect(withoutNavigation.textLeadingInset == StorePadding.p7)
        #expect(withNavigation.textTrailingInset == StorePadding.p5)
    }

    @Test func test_centeredTextInset_when_small_with_navigation_and_one_action_then_clears_both_controls() {
        // Given a small bar with a navigation control and one action (the design's reference variant)
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 1)

        // When / Then the text is inset 56 pt on both sides: inset + control + gap
        #expect(sut.centeredTextInset == StorePadding.p2 + StoreSize.topAppBarControlSize + StoreSpacing.s2)
    }

    @Test func test_centeredTextInset_when_small_with_three_actions_then_clears_the_actions() {
        // Given a small bar whose actions are wider than its navigation control
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 3)

        // When / Then the inset follows the actions cluster
        #expect(sut.centeredTextInset == StorePadding.p2 + StoreSize.topAppBarControlSize * 3 + StoreSpacing.s2)
    }

    @Test func test_centeredTextInset_when_small_without_controls_then_keeps_the_content_inset() {
        // Given a small bar with no controls at all
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: false, actionCount: 0)

        // When / Then the text keeps the p7 content inset rather than collapsing to the gap
        #expect(sut.centeredTextInset == StorePadding.p7)
    }

    @Test func test_centeredTextInset_when_medium_then_mirrors_the_leading_inset() {
        // Given medium bars: the text has its own row, so the controls never constrain it
        let withNavigation = StoreTopAppBarLayout(size: .medium, hasNavigation: true, actionCount: 3)
        let withoutNavigation = StoreTopAppBarLayout(size: .medium, hasNavigation: false, actionCount: 3)

        // When / Then the inset is symmetric to the leading inset
        #expect(withNavigation.centeredTextInset == StorePadding.p5)
        #expect(withoutNavigation.centeredTextInset == StorePadding.p7)
    }
}

@Suite struct StoreTopAppBarNavigationTests {

    @Test func test_back_then_uses_a_mirrored_chevron() {
        // Given / When the back control is built
        let sut = StoreTopAppBarNavigation.back {}

        // Then it is the regular AngleLeft glyph and mirrors in right-to-left layouts
        #expect(sut.icon.name == "AngleLeft")
        #expect(sut.icon.style == "regular")
        #expect(sut.flipsForRightToLeft)
        #expect(sut.accessibilityLabel.isEmpty == false)
    }

    @Test func test_close_then_uses_a_symmetric_xmark() {
        // Given / When the close control is built
        let sut = StoreTopAppBarNavigation.close {}

        // Then it is the regular Xmark glyph and does not mirror
        #expect(sut.icon.name == "Xmark")
        #expect(sut.icon.style == "regular")
        #expect(sut.flipsForRightToLeft == false)
        #expect(sut.accessibilityLabel.isEmpty == false)
    }
}

@Suite struct StoreTopAppBarAppearanceTests {

    @Test func test_init_when_enabled_then_uses_surface_roles() {
        // Given / When an enabled bar resolves its appearance
        let sut = StoreTopAppBarAppearance(isEnabled: true)

        // Then the container is surface bright with on-surface text and controls
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.title == .storeOnSurface)
        #expect(sut.supportingText == .storeOnSurfaceVariantLowest)
        #expect(sut.control == .storeOnSurface)
    }

    @Test func test_init_when_disabled_then_keeps_container_and_dims_foreground() {
        // Given / When a disabled bar resolves its appearance
        let sut = StoreTopAppBarAppearance(isEnabled: false)

        // Then the container is unchanged and every foreground follows the state-layer rule
        #expect(sut.background == .storeSurfaceBright)
        #expect(sut.title == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.supportingText == .storeStateLayerOnSurfaceOpacity24)
        #expect(sut.control == .storeStateLayerOnSurfaceOpacity24)
    }
}
