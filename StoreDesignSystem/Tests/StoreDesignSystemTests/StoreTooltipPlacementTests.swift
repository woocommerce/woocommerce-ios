import SwiftUI
import Testing
@testable import StoreDesignSystem

/// A placement maps to the bubble edge the arrow renders on — the inverse side, since the arrow
/// points back at the anchor. A transposition here is silent, so pin every case.
@Suite struct StoreTooltipPlacementTests {

    @Test(arguments: [
        (StoreTooltipPlacement.below, Edge.top),
        (.above, .bottom),
        (.leading, .trailing),
        (.trailing, .leading)
    ])
    func test_placement_maps_to_the_opposite_arrow_edge(placement: StoreTooltipPlacement, edge: Edge) {
        // Given a placement / When reading its arrow edge / Then it is the inverse side
        #expect(placement.arrowEdge == edge)
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
