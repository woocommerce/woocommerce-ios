import SwiftUI
import Testing
@testable import StoreDesignSystem

/// A placement maps to the bubble edge the arrow renders on — the inverse side, since the arrow
/// points back at the anchor. Placement names follow the reading direction while the geometry is
/// absolute, so horizontal placements swap in right-to-left layouts. A transposition here is
/// silent, so pin every case in both directions.
@Suite struct StoreTooltipPlacementTests {

    @Test(arguments: [
        (StoreTooltipPlacement.below, LayoutDirection.leftToRight, Edge.top),
        (.below, .rightToLeft, .top),
        (.above, .leftToRight, .bottom),
        (.above, .rightToLeft, .bottom),
        (.leading, .leftToRight, .trailing),
        (.leading, .rightToLeft, .leading),
        (.trailing, .leftToRight, .leading),
        (.trailing, .rightToLeft, .trailing)
    ])
    func test_placement_maps_to_the_opposite_arrow_edge(placement: StoreTooltipPlacement,
                                                        direction: LayoutDirection,
                                                        edge: Edge) {
        // Given a placement and a layout direction / When reading its arrow edge
        // Then it is the inverse side, with leading/trailing swapped in right-to-left
        #expect(placement.arrowEdge(in: direction) == edge)
    }

    @Test(arguments: [
        (Edge.top, Edge.bottom),
        (.bottom, .top),
        (.leading, .trailing),
        (.trailing, .leading)
    ])
    func test_opposite_inverts_the_edge(edge: Edge, opposite: Edge) {
        // Given an edge / When flipped / Then it is the opposite side
        #expect(edge.opposite == opposite)
    }
}
