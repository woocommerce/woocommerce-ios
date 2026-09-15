import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct StoreTopAppBarSizeTests {

    @Test func test_textStyles_when_small_then_uses_title_large_and_body_small_emphasized() {
        // Given / When the small bar resolves its typography
        let sut = StoreTopAppBarSize.small

        // Then it pairs the emphasized title-large title with an emphasized body-small supporting line
        #expect(sut.titleStyle == .titleLarge.emphasized)
        #expect(sut.supportingTextStyle == .bodySmall.emphasized)
    }

    @Test func test_textStyles_when_medium_then_uses_headline_small_and_body_medium_emphasized() {
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

        // When / Then the control sits p2 from the edge and the text keeps an s2 gap on both sides
        #expect(sut.barLeadingInset == StorePadding.p2)
        #expect(sut.textLeadingInset == StoreSpacing.s2)
        #expect(sut.textTrailingInset == StoreSpacing.s2)
    }

    @Test func test_insets_when_medium_then_text_row_uses_its_own_insets() {
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

    @Test func test_centeringBalance_when_control_clusters_match_then_needs_no_balance() {
        // Given a small bar with a navigation control and one action (the design's reference variant)
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 1)

        // When / Then both clusters are p2 + control wide, so centered text needs no balance
        #expect(sut.leadingCenteringBalance == 0)
        #expect(sut.trailingCenteringBalance == 0)
        #expect(sut.centeredTextGap == StoreSpacing.s2)
    }

    @Test func test_centeringBalance_when_actions_are_wider_then_balances_the_leading_side() {
        // Given a small bar whose three actions outweigh its navigation control
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 3)

        // When / Then the leading side is padded by the two extra controls
        #expect(sut.leadingCenteringBalance == StoreSize.topAppBarControlSize * 2)
        #expect(sut.trailingCenteringBalance == 0)
    }

    @Test func test_centeringBalance_when_navigation_is_wider_then_balances_the_trailing_side() {
        // Given a small bar with a navigation control and no actions
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: true, actionCount: 0)

        // When / Then the trailing side is padded by one control
        #expect(sut.leadingCenteringBalance == 0)
        #expect(sut.trailingCenteringBalance == StoreSize.topAppBarControlSize)
    }

    @Test func test_centeringBalance_when_no_navigation_then_accounts_for_the_missing_leading_inset() {
        // Given a small section bar with one action and no navigation control
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: false, actionCount: 1)

        // When / Then the leading side is padded by the action plus the trailing inset the bar has and the leading edge lacks
        #expect(sut.leadingCenteringBalance == StorePadding.p2 + StoreSize.topAppBarControlSize)
        #expect(sut.trailingCenteringBalance == 0)
    }

    @Test func test_centeredTextGap_when_no_controls_then_keeps_the_content_inset() {
        // Given a small bar with no controls at all
        let sut = StoreTopAppBarLayout(size: .small, hasNavigation: false, actionCount: 0)

        // When / Then the text keeps the p7 content inset rather than the control gap
        #expect(sut.centeredTextGap == StorePadding.p7)
        #expect(sut.leadingCenteringBalance == StorePadding.p2)
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
