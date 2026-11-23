import Testing
import SwiftUI
@testable import PointOfSale

struct POSFlowStepSlideTransitionTests {
    @Test func test_edge_when_forward_then_new_page_comes_from_trailing_and_old_page_leaves_to_leading() {
        // Given
        let direction = POSFlowStepDirection.forward

        // When
        let insertionEdge = POSFlowStepSlideTransition.edge(for: direction, phase: .willAppear)
        let removalEdge = POSFlowStepSlideTransition.edge(for: direction, phase: .didDisappear)

        // Then
        #expect(insertionEdge == .trailing)
        #expect(removalEdge == .leading)
    }

    @Test func test_edge_when_backward_then_new_page_comes_from_leading_and_old_page_leaves_to_trailing() {
        // Given
        let direction = POSFlowStepDirection.backward

        // When
        let insertionEdge = POSFlowStepSlideTransition.edge(for: direction, phase: .willAppear)
        let removalEdge = POSFlowStepSlideTransition.edge(for: direction, phase: .didDisappear)

        // Then
        #expect(insertionEdge == .leading)
        #expect(removalEdge == .trailing)
    }
}
