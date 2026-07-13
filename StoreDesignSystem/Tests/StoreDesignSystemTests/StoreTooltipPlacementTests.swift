import Testing
@testable import StoreDesignSystem

/// The anchor-relative placement API maps to the arrow-relative visual: the edge inverts (below↔top)
/// while the position along the edge is preserved. A transposition here is silent, so pin every case.
@Suite struct StoreTooltipPlacementTests {

    @Test(arguments: [
        (StoreTooltipPlacement.belowLeading, StoreTooltipArrow.Edge.top, StoreTooltipArrow.Alignment.start),
        (.belowCenter, .top, .center),
        (.belowTrailing, .top, .end),
        (.aboveLeading, .bottom, .start),
        (.aboveCenter, .bottom, .center),
        (.aboveTrailing, .bottom, .end),
        (.leadingTop, .trailing, .start),
        (.leadingCenter, .trailing, .center),
        (.leadingBottom, .trailing, .end),
        (.trailingTop, .leading, .start),
        (.trailingCenter, .leading, .center),
        (.trailingBottom, .leading, .end)
    ])
    func test_placement_maps_to_expected_arrow(placement: StoreTooltipPlacement,
                                               edge: StoreTooltipArrow.Edge,
                                               alignment: StoreTooltipArrow.Alignment) {
        // Given a placement / When reading its mapped arrow / Then the edge inverts and position is kept
        #expect(placement.arrow.edge == edge)
        #expect(placement.arrow.alignment == alignment)
    }

    @Test(arguments: [
        (StoreTooltipArrow.topLeading, StoreTooltipArrow.Edge.bottom, StoreTooltipArrow.Alignment.start),
        (.bottomCenter, .top, .center),
        (.leadingTop, .trailing, .start),
        (.trailingBottom, .leading, .end)
    ])
    func test_flipped_inverts_edge_and_keeps_alignment(arrow: StoreTooltipArrow,
                                                       flippedEdge: StoreTooltipArrow.Edge,
                                                       alignment: StoreTooltipArrow.Alignment) {
        // Given an arrow / When flipped / Then the edge inverts and the alignment is preserved
        #expect(arrow.flipped.edge == flippedEdge)
        #expect(arrow.flipped.alignment == alignment)
    }
}
