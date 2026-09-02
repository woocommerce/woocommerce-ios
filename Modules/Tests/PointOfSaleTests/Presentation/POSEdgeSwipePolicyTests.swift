import SwiftUI
import Testing
@testable import PointOfSale

struct POSEdgeSwipePolicyTests {
    @Test func test_normalized_when_left_to_right_then_positive_translation_moves_back() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When / Then
        #expect(policy.normalized(40) == 40)
        #expect(policy.normalized(-40) == -40)
    }

    @Test func test_normalized_when_right_to_left_then_negative_translation_moves_back() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        // When / Then
        #expect(policy.normalized(-40) == 40)
        #expect(policy.normalized(40) == -40)
    }

    @Test func test_clampedTranslation_when_drag_exceeds_bounds_then_clamps_to_view_width() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When / Then
        #expect(policy.clampedTranslation(-10, totalWidth: 100) == 0)
        #expect(policy.clampedTranslation(50, totalWidth: 100) == 50)
        #expect(policy.clampedTranslation(120, totalWidth: 100) == 100)
    }

    @Test func test_shouldComplete_when_current_translation_crosses_threshold_then_returns_true() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When
        let result = policy.shouldComplete(translation: 36, predictedEndTranslation: 36, totalWidth: 100)

        // Then
        #expect(result)
    }

    @Test func test_shouldComplete_when_projected_translation_crosses_threshold_then_returns_true() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        // When
        let result = policy.shouldComplete(translation: -10, predictedEndTranslation: -40, totalWidth: 100)

        // Then
        #expect(result)
    }

    @Test func test_shouldComplete_when_drag_moves_away_from_leading_edge_then_returns_false() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        // When
        let result = policy.shouldComplete(translation: 40, predictedEndTranslation: 60, totalWidth: 100)

        // Then
        #expect(!result)
    }

    @Test func test_shouldComplete_when_translation_sits_exactly_on_threshold_then_returns_false() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When
        let result = policy.shouldComplete(translation: 35, predictedEndTranslation: 35, totalWidth: 100)

        // Then
        #expect(!result)
    }

    @Test func test_completionDistance_when_width_is_unknown_then_falls_back_to_a_fixed_distance() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When
        let distance = policy.completionDistance(totalWidth: 0)

        // Then
        #expect(distance == POSEdgeSwipePolicy.fallbackCompletionDistance)
    }

    @Test func test_shouldComplete_when_width_is_unknown_then_a_long_swipe_still_completes() {
        // Given a container that has not reported its width, a strict comparison against a zero
        // threshold would never complete however far the merchant swipes.
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When
        let result = policy.shouldComplete(translation: 120, predictedEndTranslation: 120, totalWidth: 0)

        // Then
        #expect(result)
    }

    @Test func test_startsAtLeadingEdge_when_left_to_right_then_only_the_left_edge_qualifies() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When / Then
        #expect(policy.startsAtLeadingEdge(0, totalWidth: 400))
        #expect(policy.startsAtLeadingEdge(POSEdgeSwipePolicy.activationWidth, totalWidth: 400))
        #expect(!policy.startsAtLeadingEdge(POSEdgeSwipePolicy.activationWidth + 1, totalWidth: 400))
        #expect(!policy.startsAtLeadingEdge(400, totalWidth: 400))
    }

    @Test func test_startsAtLeadingEdge_when_right_to_left_then_only_the_right_edge_qualifies() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        // When / Then
        #expect(policy.startsAtLeadingEdge(400, totalWidth: 400))
        #expect(policy.startsAtLeadingEdge(400 - POSEdgeSwipePolicy.activationWidth, totalWidth: 400))
        #expect(!policy.startsAtLeadingEdge(400 - POSEdgeSwipePolicy.activationWidth - 1, totalWidth: 400))
        #expect(!policy.startsAtLeadingEdge(0, totalWidth: 400))
    }

    @Test func test_isPredominantlyHorizontal_when_drag_is_mostly_vertical_then_returns_false() {
        // Given
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        // When / Then
        #expect(policy.isPredominantlyHorizontal(CGSize(width: 60, height: 20)))
        #expect(!policy.isPredominantlyHorizontal(CGSize(width: 20, height: 60)))
        #expect(!policy.isPredominantlyHorizontal(CGSize(width: 40, height: 40)))
    }
}
