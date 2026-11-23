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

    @Test func test_pacer_when_steps_change_while_the_modal_arrives_then_shows_the_latest_without_sliding_once_it_arrived() {
        // Given
        var sut = POSModalFlowStepPacer(step: "opening")

        // When
        sut.show("searching")
        sut.show("failed")
        let shownWhileArriving = sut.shown
        sut.motionEnded()

        // Then
        #expect(shownWhileArriving == "opening")
        #expect(sut.shown == "failed")
        #expect(sut.isSliding == false)
        #expect(sut.slideCount == 0)
    }

    @Test func test_pacer_when_a_step_changes_at_rest_then_slides_to_it_immediately() {
        // Given
        var sut = POSModalFlowStepPacer(step: "first")
        sut.motionEnded()

        // When
        sut.show("second")

        // Then
        #expect(sut.shown == "second")
        #expect(sut.isSliding)
        #expect(sut.slideCount == 1)
    }

    @Test func test_pacer_when_a_step_comes_and_goes_during_a_slide_then_returns_with_a_second_slide_after_the_first() {
        // Given
        var sut = POSModalFlowStepPacer(step: "failed")
        sut.motionEnded()

        // When
        sut.show("searching")
        sut.show("failed")
        let shownDuringSlide = sut.shown
        let slidesDuringSlide = sut.slideCount
        sut.motionEnded()

        // Then
        #expect(shownDuringSlide == "searching")
        #expect(slidesDuringSlide == 1)
        #expect(sut.shown == "failed")
        #expect(sut.isSliding)
        #expect(sut.slideCount == 2)
    }

    @Test func test_pacer_when_several_steps_pass_during_a_slide_then_skips_to_the_latest() {
        // Given
        var sut = POSModalFlowStepPacer(step: "first")
        sut.motionEnded()
        sut.show("second")

        // When
        sut.show("third")
        sut.show("fourth")
        sut.motionEnded()

        // Then
        #expect(sut.shown == "fourth")
        #expect(sut.slideCount == 2)
    }

    @Test func test_pacer_when_a_slide_ends_with_nothing_waiting_then_rests() {
        // Given
        var sut = POSModalFlowStepPacer(step: "first")
        sut.motionEnded()
        sut.show("second")

        // When
        sut.motionEnded()

        // Then
        #expect(sut.shown == "second")
        #expect(sut.isSliding == false)
        #expect(sut.slideCount == 1)
    }
}
