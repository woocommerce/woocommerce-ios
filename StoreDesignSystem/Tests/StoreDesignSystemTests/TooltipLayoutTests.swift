import CoreGraphics
import Testing
@testable import StoreDesignSystem

@Suite struct TooltipLayoutTests {
    /// A 400×800 "screen" used for all cases.
    private let bounds = CGRect(x: 0, y: 0, width: 400, height: 800)

    private func layout(anchor: CGRect) -> TooltipLayout {
        TooltipLayout(anchorFrame: anchor, bounds: bounds)
    }

    // MARK: - resolvedArrow

    @Test func test_resolvedArrow_when_anchor_unmeasured_then_returns_preferred() {
        // Given a layout whose anchor hasn't been measured yet
        let sut = TooltipLayout(anchorFrame: .zero, bounds: bounds)
        // When resolving with a preference / Then it is returned as-is (no flip without geometry)
        #expect(sut.resolvedArrow(preferred: .bottomCenter).edge == .bottom)
    }

    @Test func test_resolvedArrow_when_anchor_unmeasured_and_no_preference_then_defaults_below() {
        // Given an unmeasured anchor and no preference
        let sut = TooltipLayout(anchorFrame: .zero, bounds: bounds)
        // When resolving / Then it defaults to "below" (a .top arrow)
        let arrow = sut.resolvedArrow(preferred: nil)
        #expect(arrow.edge == .top)
        #expect(arrow.alignment == .center)
    }

    @Test func test_resolvedArrow_when_preferred_side_has_room_then_honored() {
        // Given an anchor high on screen with room below
        let sut = layout(anchor: CGRect(x: 190, y: 100, width: 20, height: 20))
        // When / Then the preferred "below" placement is honored
        #expect(sut.resolvedArrow(preferred: .topCenter).edge == .top)
    }

    @Test func test_resolvedArrow_when_preferred_side_lacks_room_then_flips() {
        // Given an anchor near the bottom, where "below" has no room
        let sut = layout(anchor: CGRect(x: 190, y: 770, width: 20, height: 20))
        // When / Then it flips to "above"
        #expect(sut.resolvedArrow(preferred: .topCenter).edge == .bottom)
    }

    @Test func test_resolvedArrow_when_no_preference_then_matches_autoArrow() {
        // Given an anchor and no preference
        let sut = layout(anchor: CGRect(x: 190, y: 100, width: 20, height: 20))
        // When resolving / Then it equals the auto-picked arrow
        let resolved = sut.resolvedArrow(preferred: nil)
        let auto = sut.autoArrow()
        #expect(resolved.edge == auto.edge)
        #expect(resolved.alignment == auto.alignment)
    }

    // MARK: - autoArrow

    @Test(arguments: [
        (CGFloat(100), StoreTooltipArrow.Edge.top),    // top half -> opens below
        (700, .bottom)                                  // bottom half -> opens above
    ])
    func test_autoArrow_opens_toward_roomier_vertical_side(anchorY: CGFloat, expected: StoreTooltipArrow.Edge) {
        // Given an anchor high or low on screen
        let sut = layout(anchor: CGRect(x: 190, y: anchorY, width: 20, height: 20))
        // When / Then it opens toward the side with more room
        #expect(sut.autoArrow().edge == expected)
    }

    @Test(arguments: [
        (CGFloat(10), StoreTooltipArrow.Alignment.start),   // leading third
        (200, .center),                                     // middle third
        (370, .end)                                         // trailing third
    ])
    func test_horizontalAlignment_follows_the_anchor_third(anchorX: CGFloat, expected: StoreTooltipArrow.Alignment) {
        // Given an anchor in the leading / middle / trailing third
        let sut = layout(anchor: CGRect(x: anchorX, y: 400, width: 20, height: 20))
        // When / Then the along-edge alignment matches
        #expect(sut.horizontalAlignment() == expected)
    }

    // MARK: - shouldFlip

    @Test(arguments: [
        (StoreTooltipArrow.topCenter, CGRect(x: 190, y: 680, width: 20, height: 20), true),    // no room below
        (.topCenter, CGRect(x: 190, y: 100, width: 20, height: 20), false),                    // room below
        (.bottomCenter, CGRect(x: 190, y: 100, width: 20, height: 20), true),                  // no room above
        (.leadingCenter, CGRect(x: 360, y: 400, width: 20, height: 20), true),                 // no room on trailing side
        (.trailingCenter, CGRect(x: 10, y: 400, width: 20, height: 20), true)                   // no room on leading side
    ])
    func test_shouldFlip_when_side_is_cramped(arrow: StoreTooltipArrow, anchor: CGRect, expected: Bool) {
        // Given an anchor near (or far from) the placement's edge
        let sut = layout(anchor: anchor)
        // When / Then it flips only when the side can't fit the bubble
        #expect(sut.shouldFlip(arrow) == expected)
    }

    @Test func test_shouldFlip_uses_measured_height_over_nominal() {
        // Given an anchor with 160pt below it — enough for the nominal height (150) but not a tall bubble
        let sut = layout(anchor: CGRect(x: 190, y: 620, width: 20, height: 20))
        // When the measured bubble is 200pt tall / Then it flips; with no measurement it wouldn't
        #expect(sut.shouldFlip(.topCenter, bubbleSize: CGSize(width: 200, height: 200)) == true)
        #expect(sut.shouldFlip(.topCenter, bubbleSize: .zero) == false)
    }

    // MARK: - availableBubbleWidth

    @Test func test_availableBubbleWidth_capped_to_max_for_centered_anchor() {
        // Given a centered anchor with generous room / When / Then the width is capped to the maximum
        let sut = layout(anchor: CGRect(x: 190, y: 100, width: 20, height: 20))
        #expect(sut.availableBubbleWidth(for: .topCenter) == 300)
    }

    @Test func test_availableBubbleWidth_leading_arrow_uses_trailing_space() {
        // Given a leading arrow / When / Then the width is the trailing space: 384 - 210 - 10
        let sut = layout(anchor: CGRect(x: 190, y: 400, width: 20, height: 20))
        #expect(sut.availableBubbleWidth(for: .leadingCenter) == 164)
    }

    @Test func test_availableBubbleWidth_clamped_to_min_when_cramped() {
        // Given a start arrow near the right edge with only ~31pt of room / When / Then it clamps up to min
        let sut = layout(anchor: CGRect(x: 374, y: 400, width: 20, height: 20))
        #expect(sut.availableBubbleWidth(for: .topLeading) == 80)
    }

    // MARK: - bubbleOffset (arrow tip lands on the anchor; bubble stays on screen)

    /// Where the arrow tip ends up after the bubble is centered on the anchor and offset by the layout.
    private func arrowTip(anchor: CGRect, bubble: CGSize, arrow: StoreTooltipArrow) -> CGPoint {
        let offset = layout(anchor: anchor).bubbleOffset(for: arrow, bubbleSize: bubble)
        let center = CGPoint(x: anchor.midX + offset.width, y: anchor.midY + offset.height)
        let origin = CGPoint(x: center.x - bubble.width / 2, y: center.y - bubble.height / 2)

        func along(_ length: CGFloat) -> CGFloat {
            switch arrow.alignment {
            case .center: length / 2
            case .start: TooltipMetrics.arrowTipInset
            case .end: length - TooltipMetrics.arrowTipInset
            }
        }

        switch arrow.edge {
        case .top: return CGPoint(x: origin.x + along(bubble.width), y: origin.y)
        case .bottom: return CGPoint(x: origin.x + along(bubble.width), y: origin.y + bubble.height)
        case .leading: return CGPoint(x: origin.x, y: origin.y + along(bubble.height))
        case .trailing: return CGPoint(x: origin.x + bubble.width, y: origin.y + along(bubble.height))
        }
    }

    /// The bubble rect after centering on the anchor and applying the layout offset.
    private func bubbleRect(anchor: CGRect, bubble: CGSize, arrow: StoreTooltipArrow) -> CGRect {
        let offset = layout(anchor: anchor).bubbleOffset(for: arrow, bubbleSize: bubble)
        let center = CGPoint(x: anchor.midX + offset.width, y: anchor.midY + offset.height)
        return CGRect(x: center.x - bubble.width / 2, y: center.y - bubble.height / 2,
                      width: bubble.width, height: bubble.height)
    }

    @Test(arguments: [StoreTooltipArrow.topCenter, .topLeading, .topTrailing])
    func test_below_arrow_tip_lands_on_anchor_bottom_center(arrow: StoreTooltipArrow) {
        // Given a "below" arrow with any along-edge alignment, on an anchor where the bubble fits
        let anchor = CGRect(x: 180, y: 100, width: 40, height: 40)
        // When positioning / Then crossShift lands the tip on the anchor's bottom-center regardless of alignment
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 200, height: 120), arrow: arrow)
        #expect(abs(tip.x - anchor.midX) < 0.001)
        #expect(abs(tip.y - (anchor.maxY + TooltipLayout.Constants.anchorGap)) < 0.001)
    }

    @Test func test_bubbleOffset_above_puts_arrow_tip_at_anchor_top_center() {
        // Given an anchor with room above and an "above" arrow / When / Then the tip sits on the anchor's top
        let anchor = CGRect(x: 100, y: 400, width: 40, height: 40)
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 200, height: 120), arrow: .bottomCenter)
        #expect(abs(tip.x - anchor.midX) < 0.001)
        #expect(abs(tip.y - (anchor.minY - TooltipLayout.Constants.anchorGap)) < 0.001)
    }

    @Test func test_bubbleOffset_trailing_arrow_puts_tip_on_anchor_leading_edge() {
        // Given a trailing arrow (bubble on the leading side) / When / Then the tip sits on the leading edge
        let anchor = CGRect(x: 300, y: 400, width: 40, height: 40)
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 150, height: 100), arrow: .trailingCenter)
        #expect(abs(tip.x - (anchor.minX - TooltipLayout.Constants.anchorGap)) < 0.001)
        #expect(abs(tip.y - anchor.midY) < 0.001)
    }

    @Test func test_bubbleOffset_leading_arrow_puts_tip_on_anchor_trailing_edge() {
        // Given a leading arrow (bubble on the trailing side) / When / Then the tip sits on the trailing edge
        let anchor = CGRect(x: 60, y: 400, width: 40, height: 40)
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 150, height: 100), arrow: .leadingCenter)
        #expect(abs(tip.x - (anchor.maxX + TooltipLayout.Constants.anchorGap)) < 0.001)
        #expect(abs(tip.y - anchor.midY) < 0.001)
    }

    @Test func test_bubbleOffset_clamps_bubble_on_screen_when_anchor_near_left_edge() {
        // Given a start arrow on an anchor flush against the left edge (raw placement clips off screen)
        let anchor = CGRect(x: 0, y: 400, width: 24, height: 24)
        // When positioning / Then the bubble is nudged back within the left margin
        let rect = bubbleRect(anchor: anchor, bubble: CGSize(width: 200, height: 120), arrow: .topLeading)
        #expect(rect.minX >= bounds.minX + TooltipLayout.Constants.screenMargin - 0.001)
        #expect(rect.maxX <= bounds.maxX - TooltipLayout.Constants.screenMargin + 0.001)
    }

    @Test func test_bubbleOffset_clamps_bubble_on_screen_when_side_placement_near_top_edge() {
        // Given a side placement whose bubble extends upward, on an anchor near the top edge
        let anchor = CGRect(x: 200, y: 10, width: 24, height: 24)
        // When positioning a tall bubble / Then it is nudged back within the top margin
        let rect = bubbleRect(anchor: anchor, bubble: CGSize(width: 150, height: 200), arrow: .leadingBottom)
        #expect(rect.minY >= bounds.minY + TooltipLayout.Constants.screenMargin - 0.001)
        #expect(rect.maxY <= bounds.maxY - TooltipLayout.Constants.screenMargin + 0.001)
    }
}
