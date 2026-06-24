import Testing
import CoreGraphics
@testable import StoreDesignSystem

/// StoreRadius mirrors the Figma "Corner Radius/Name" scale. These tests pin the shape
/// the design intends — 7 strictly-ascending steps from zero up to the `full` pill
/// sentinel — plus the Medium = 8 anchor cross-checked against the Figma variables export.
struct StoreRadiusTests {
    private static let ramp: [CGFloat] = [
        StoreRadius.none, StoreRadius.extraSmall, StoreRadius.small, StoreRadius.medium,
        StoreRadius.large, StoreRadius.extraLarge, StoreRadius.full
    ]

    @Test func test_ramp_has_7_steps() {
        #expect(Self.ramp.count == 7)
    }

    @Test func test_scale_starts_at_zero() {
        #expect(StoreRadius.none == 0)
    }

    @Test func test_scale_is_strictly_ascending() {
        #expect(zip(Self.ramp, Self.ramp.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test func test_anchor_matches_figma_export() {
        // Cross-checked against the Figma variables export (Corner Radius/Medium = 8).
        #expect(StoreRadius.medium == 8)
    }

    @Test func test_full_is_large_enough_to_fully_round() {
        // `full` must round any reasonably sized element into a capsule.
        #expect(StoreRadius.full >= 999)
    }
}
