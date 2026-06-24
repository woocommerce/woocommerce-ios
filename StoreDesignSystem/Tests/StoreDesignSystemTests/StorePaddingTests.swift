import Testing
import CoreGraphics
@testable import StoreDesignSystem

/// StorePadding mirrors the Figma "Padding/N" ramp (0...12). As with spacing, these
/// tests pin the *shape* the design intends — 13 steps, starting at zero, strictly
/// ascending — plus the Padding/3 = 8 anchor cross-checked against the Figma variables
/// export. Padding is intentionally NOT asserted equal to spacing: the two are separate
/// scales and are allowed to diverge.
struct StorePaddingTests {
    private static let ramp: [CGFloat] = [
        StorePadding.p0, StorePadding.p1, StorePadding.p2, StorePadding.p3,
        StorePadding.p4, StorePadding.p5, StorePadding.p6, StorePadding.p7,
        StorePadding.p8, StorePadding.p9, StorePadding.p10, StorePadding.p11,
        StorePadding.p12
    ]

    @Test func test_ramp_has_13_steps() {
        #expect(Self.ramp.count == 13)
    }

    @Test func test_scale_starts_at_zero() {
        #expect(StorePadding.p0 == 0)
    }

    @Test func test_scale_is_strictly_ascending() {
        #expect(zip(Self.ramp, Self.ramp.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test func test_anchor_matches_figma_export() {
        // Cross-checked against the Figma variables export (Padding/3 = 8).
        #expect(StorePadding.p3 == 8)
    }
}
