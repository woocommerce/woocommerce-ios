import CoreGraphics
import SwiftUI
import Testing
@testable import StoreDesignSystem

@Suite struct TooltipLayoutTests {
    /// A 400×800 "screen" used for all cases.
    private let bounds = CGRect(x: 0, y: 0, width: 400, height: 800)

    private func layout(anchor: CGRect) -> TooltipLayout {
        TooltipLayout(anchorFrame: anchor, bounds: bounds)
    }

    // MARK: - resolvedArrowEdge

    @Test func test_resolvedArrowEdge_when_anchor_unmeasured_then_returns_preferred() {
        // Given a layout whose anchor hasn't been measured yet
        let sut = TooltipLayout(anchorFrame: .zero, bounds: bounds)
        // When resolving with a preference / Then it is returned as-is (no flip without geometry)
        #expect(sut.resolvedArrowEdge(preferred: .bottom) == .bottom)
    }

    @Test func test_resolvedArrowEdge_when_anchor_unmeasured_and_no_preference_then_defaults_below() {
        // Given an unmeasured anchor and no preference
        let sut = TooltipLayout(anchorFrame: .zero, bounds: bounds)
        // When resolving / Then it defaults to "below" (a .top arrow)
        #expect(sut.resolvedArrowEdge(preferred: nil) == .top)
    }

    @Test func test_resolvedArrowEdge_when_preferred_side_has_room_then_honored() {
        // Given an anchor high on screen with room below
        let sut = layout(anchor: CGRect(x: 190, y: 100, width: 20, height: 20))
        // When / Then the preferred "below" placement is honored
        #expect(sut.resolvedArrowEdge(preferred: .top) == .top)
    }

    @Test func test_resolvedArrowEdge_when_preferred_side_lacks_room_then_flips() {
        // Given an anchor near the bottom, where "below" has no room
        let sut = layout(anchor: CGRect(x: 190, y: 770, width: 20, height: 20))
        // When / Then it flips to "above"
        #expect(sut.resolvedArrowEdge(preferred: .top) == .bottom)
    }

    @Test(arguments: [
        (CGFloat(100), Edge.top),   // top half -> opens below
        (700, .bottom)              // bottom half -> opens above
    ])
    func test_resolvedArrowEdge_auto_opens_toward_roomier_vertical_side(anchorY: CGFloat, expected: Edge) {
        // Given an anchor high or low on screen and no preference
        let sut = layout(anchor: CGRect(x: 190, y: anchorY, width: 20, height: 20))
        // When / Then it opens toward the side with more room
        #expect(sut.resolvedArrowEdge(preferred: nil) == expected)
    }

    // MARK: - shouldFlip

    @Test(arguments: [
        (Edge.top, CGRect(x: 190, y: 680, width: 20, height: 20), true),    // no room below
        (.top, CGRect(x: 190, y: 100, width: 20, height: 20), false),       // room below
        (.bottom, CGRect(x: 190, y: 100, width: 20, height: 20), true),     // no room above
        (.leading, CGRect(x: 360, y: 400, width: 20, height: 20), true),    // no room on trailing side
        (.trailing, CGRect(x: 10, y: 400, width: 20, height: 20), true)     // no room on leading side
    ])
    func test_shouldFlip_when_side_is_cramped(arrowEdge: Edge, anchor: CGRect, expected: Bool) {
        // Given an anchor near (or far from) the placement's edge
        let sut = layout(anchor: anchor)
        // When / Then it flips only when the side can't fit the bubble
        #expect(sut.shouldFlip(arrowEdge) == expected)
    }

    @Test func test_shouldFlip_uses_measured_height_over_nominal() {
        // Given an anchor with 160pt below it — enough for the nominal height (150) but not a tall bubble
        let sut = layout(anchor: CGRect(x: 190, y: 620, width: 20, height: 20))
        // When the measured bubble is 200pt tall / Then it flips; with no measurement it wouldn't
        #expect(sut.shouldFlip(.top, bubbleSize: CGSize(width: 200, height: 200)) == true)
        #expect(sut.shouldFlip(.top, bubbleSize: .zero) == false)
    }

    // MARK: - availableBubbleWidth

    @Test func test_availableBubbleWidth_for_vertical_placement_is_capped_to_max() {
        // Given a below placement (the bubble slides along the edge, so the full width is usable)
        let sut = layout(anchor: CGRect(x: 20, y: 100, width: 20, height: 20))
        // When / Then the width is the screen minus margins, capped to the maximum
        #expect(sut.availableBubbleWidth(for: .top) == 300)
    }

    @Test func test_availableBubbleWidth_leading_arrow_uses_trailing_space() {
        // Given a leading arrow (bubble on the trailing side) / When / Then the width is 392 - 210 - 10
        let sut = layout(anchor: CGRect(x: 190, y: 400, width: 20, height: 20))
        #expect(sut.availableBubbleWidth(for: .leading) == 172)
    }

    @Test func test_availableBubbleWidth_clamped_to_min_when_cramped() {
        // Given a leading arrow on an anchor near the right edge with no room / When / Then it clamps up to min
        let sut = layout(anchor: CGRect(x: 374, y: 400, width: 20, height: 20))
        #expect(sut.availableBubbleWidth(for: .leading) == 80)
    }

    // MARK: - bubbleOffset + arrowTipAlongEdge (bubble stays on screen; arrow tip points at the anchor)

    /// The bubble rect after centering on the anchor and applying the layout offset.
    private func bubbleRect(anchor: CGRect, bubble: CGSize, arrowEdge: Edge) -> CGRect {
        let offset = layout(anchor: anchor).bubbleOffset(for: arrowEdge, bubbleSize: bubble)
        return CGRect(x: anchor.midX + offset.width - bubble.width / 2,
                      y: anchor.midY + offset.height - bubble.height / 2,
                      width: bubble.width, height: bubble.height)
    }

    /// Where the arrow tip ends up on screen, combining the bubble offset and the tip's slide.
    private func arrowTip(anchor: CGRect, bubble: CGSize, arrowEdge: Edge) -> CGPoint {
        let sut = layout(anchor: anchor)
        let offset = sut.bubbleOffset(for: arrowEdge, bubbleSize: bubble)
        let tip = sut.arrowTipAlongEdge(for: arrowEdge, bubbleSize: bubble, bubbleOffset: offset)
        let rect = bubbleRect(anchor: anchor, bubble: bubble, arrowEdge: arrowEdge)
        switch arrowEdge {
        case .top: return CGPoint(x: rect.minX + tip, y: rect.minY)
        case .bottom: return CGPoint(x: rect.minX + tip, y: rect.maxY)
        case .leading: return CGPoint(x: rect.minX, y: rect.minY + tip)
        case .trailing: return CGPoint(x: rect.maxX, y: rect.minY + tip)
        }
    }

    @Test func test_below_placement_puts_arrow_tip_at_anchor_bottom_center() {
        // Given a "below" placement on an anchor with room all around
        let anchor = CGRect(x: 180, y: 100, width: 40, height: 40)
        // When positioning / Then the tip sits just under the anchor's bottom center
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 200, height: 120), arrowEdge: .top)
        #expect(abs(tip.x - anchor.midX) < 0.001)
        #expect(abs(tip.y - (anchor.maxY + TooltipLayout.Constants.anchorGap)) < 0.001)
    }

    @Test func test_trailing_side_placement_puts_arrow_tip_at_anchor_leading_edge() {
        // Given a trailing arrow (bubble on the leading side) / When / Then the tip sits on the leading edge
        let anchor = CGRect(x: 300, y: 400, width: 40, height: 40)
        let tip = arrowTip(anchor: anchor, bubble: CGSize(width: 150, height: 100), arrowEdge: .trailing)
        #expect(abs(tip.x - (anchor.minX - TooltipLayout.Constants.anchorGap)) < 0.001)
        #expect(abs(tip.y - anchor.midY) < 0.001)
    }

    @Test func test_bubbleOffset_clamps_bubble_on_screen_when_anchor_near_left_edge() {
        // Given an anchor flush against the left edge (a centered bubble would clip off screen)
        let anchor = CGRect(x: 0, y: 400, width: 24, height: 24)
        // When positioning / Then the bubble is nudged back within the left margin
        let rect = bubbleRect(anchor: anchor, bubble: CGSize(width: 200, height: 120), arrowEdge: .top)
        #expect(rect.minX >= bounds.minX + TooltipLayout.Constants.screenMargin - 0.001)
        #expect(rect.maxX <= bounds.maxX - TooltipLayout.Constants.screenMargin + 0.001)
    }

    @Test func test_arrowTip_centered_when_bubble_is_not_clamped() {
        // Given a roomy centered anchor where the bubble needs no clamping
        let sut = layout(anchor: CGRect(x: 180, y: 100, width: 40, height: 40))
        let bubble = CGSize(width: 200, height: 120)
        // When placing the arrow / Then it sits at the middle of the edge
        let offset = sut.bubbleOffset(for: .top, bubbleSize: bubble)
        #expect(sut.arrowTipAlongEdge(for: .top, bubbleSize: bubble, bubbleOffset: offset) == 100)
    }

    @Test func test_arrowTip_slides_toward_anchor_when_bubble_is_clamped() {
        // Given an anchor near the right edge, so the bubble clamps left
        let sut = layout(anchor: CGRect(x: 300, y: 100, width: 20, height: 20))
        let bubble = CGSize(width: 200, height: 120)
        // When placing the arrow / Then it slides past the center toward the anchor…
        let offset = sut.bubbleOffset(for: .top, bubbleSize: bubble)
        let tip = sut.arrowTipAlongEdge(for: .top, bubbleSize: bubble, bubbleOffset: offset)
        #expect(tip == 118)
        // …but not all the way to the corner, since this clamp is mild
        #expect(tip < 200 - TooltipLayout.Constants.minArrowTipInset)
    }

    @Test func test_arrowTip_never_slides_closer_than_min_inset() {
        // Given an anchor jammed against the right edge (a large clamp)
        let sut = layout(anchor: CGRect(x: 385, y: 100, width: 10, height: 10))
        let bubble = CGSize(width: 200, height: 120)
        // When placing the arrow / Then it stops at the closest it may sit to the rounded corner
        let offset = sut.bubbleOffset(for: .top, bubbleSize: bubble)
        let tip = sut.arrowTipAlongEdge(for: .top, bubbleSize: bubble, bubbleOffset: offset)
        #expect(tip == 200 - TooltipLayout.Constants.minArrowTipInset)
    }

    @Test func test_arrowTip_slides_along_the_vertical_edge_for_a_side_placement() {
        // Given a leading arrow (bubble on the trailing side) whose anchor is near the bottom, so the
        // bubble clamps up
        let sut = layout(anchor: CGRect(x: 60, y: 740, width: 20, height: 20))
        let bubble = CGSize(width: 150, height: 100)
        // When placing the arrow / Then the tip slides down its (vertical) edge toward the anchor
        let offset = sut.bubbleOffset(for: .leading, bubbleSize: bubble)
        #expect(sut.arrowTipAlongEdge(for: .leading, bubbleSize: bubble, bubbleOffset: offset) == 58)
    }
}
