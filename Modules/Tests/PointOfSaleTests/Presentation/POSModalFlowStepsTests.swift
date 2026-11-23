import Testing
import SwiftUI
@testable import PointOfSale

struct POSModalFlowStepsTests {
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

    @Test func test_direction_when_steps_change_without_back_then_forward() {
        // Given
        let sut = POSModalFlowStepNavigation()

        // When
        sut.show(step: "first")
        sut.show(step: "second")

        // Then
        #expect(sut.direction == .forward)
    }

    @Test func test_direction_when_back_precedes_a_step_change_then_backward_for_that_change_only() {
        // Given
        let sut = POSModalFlowStepNavigation()
        sut.show(step: "first")
        sut.show(step: "second")

        // When
        sut.goBackwardOnNextStep()
        sut.show(step: "first")
        let directionAfterBack = sut.direction
        sut.show(step: "second")

        // Then
        #expect(directionAfterBack == .backward)
        #expect(sut.direction == .forward)
    }

    @Test func test_direction_when_the_same_step_renders_again_then_unchanged() {
        // Given
        let sut = POSModalFlowStepNavigation()
        sut.show(step: "first")
        sut.goBackwardOnNextStep()
        sut.show(step: "second")

        // When
        sut.show(step: "second")

        // Then
        #expect(sut.direction == .backward)
    }
}
