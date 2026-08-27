import SwiftUI
import Testing
@testable import PointOfSale

struct POSEdgeSwipePolicyTests {
    @Test func normalized_translation_when_left_to_right_then_positive_translation_moves_back() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        #expect(policy.normalized(40) == 40)
        #expect(policy.normalized(-40) == -40)
    }

    @Test func normalized_translation_when_right_to_left_then_negative_translation_moves_back() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        #expect(policy.normalized(-40) == 40)
        #expect(policy.normalized(40) == -40)
    }

    @Test func clamped_translation_when_drag_exceeds_bounds_then_clamps_to_view_width() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        #expect(policy.clampedTranslation(-10, totalWidth: 100) == 0)
        #expect(policy.clampedTranslation(50, totalWidth: 100) == 50)
        #expect(policy.clampedTranslation(120, totalWidth: 100) == 100)
    }

    @Test func should_complete_when_current_translation_crosses_threshold_then_returns_true() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .leftToRight)

        #expect(policy.shouldComplete(translation: 36, predictedEndTranslation: 36, totalWidth: 100))
    }

    @Test func should_complete_when_projected_translation_crosses_threshold_then_returns_true() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        #expect(policy.shouldComplete(translation: -10, predictedEndTranslation: -40, totalWidth: 100))
    }

    @Test func should_complete_when_drag_moves_away_from_leading_edge_then_returns_false() {
        let policy = POSEdgeSwipePolicy(layoutDirection: .rightToLeft)

        #expect(!policy.shouldComplete(translation: 40, predictedEndTranslation: 60, totalWidth: 100))
    }
}
