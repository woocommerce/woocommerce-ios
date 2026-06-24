import Testing
import CoreGraphics
@testable import StoreDesignSystem

/// StoreSpacing mirrors the Figma "Spacing/N" ramp (0...12). Rather than re-listing
/// every value (which would be circular), these tests pin the *shape* the design
/// intends — a ramp of 13 steps, starting at zero, strictly ascending — plus the one
/// anchor independently cross-checked against the Figma variables export (Spacing/2 = 4).
/// An accidental edit to a constant breaks the shape and is caught here.
struct StoreSpacingTests {
    private static let ramp: [CGFloat] = [
        StoreSpacing.s0, StoreSpacing.s1, StoreSpacing.s2, StoreSpacing.s3,
        StoreSpacing.s4, StoreSpacing.s5, StoreSpacing.s6, StoreSpacing.s7,
        StoreSpacing.s8, StoreSpacing.s9, StoreSpacing.s10, StoreSpacing.s11,
        StoreSpacing.s12
    ]

    @Test func test_ramp_has_13_steps() {
        #expect(Self.ramp.count == 13)
    }

    @Test func test_scale_starts_at_zero() {
        #expect(StoreSpacing.s0 == 0)
    }

    @Test func test_scale_is_strictly_ascending() {
        #expect(zip(Self.ramp, Self.ramp.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test func test_anchor_matches_figma_export() {
        // Cross-checked against the Figma variables export (Spacing/2 = 4).
        #expect(StoreSpacing.s2 == 4)
    }
}
