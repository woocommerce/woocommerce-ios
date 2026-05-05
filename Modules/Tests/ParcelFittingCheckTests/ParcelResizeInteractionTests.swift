import CoreGraphics
import Testing
import simd
@testable import ParcelFittingCheck

@Suite("ParcelResizeInteraction")
struct ParcelResizeInteractionTests {

    // MARK: - Fixtures

    private static let initialPosition = SIMD3<Float>(0, 0, 0)
    private static let initialScale = SIMD3<Float>(0.20, 0.10, 0.15)

    /// Linear orthographic projection: world X horizontal, world Y vertical
    /// (screen Y is down so it's negated), world Z dropped. With this
    /// projection, a horizontal pinch picks X and a vertical pinch picks Y;
    /// Z is invisible so its score is zero.
    private static func linearProjection(
        isUpperHalfHit: @escaping (CGPoint) -> Bool = { _ in false }
    ) -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { world in
                CGPoint(x: CGFloat(world.x) * 1000, y: CGFloat(-world.y) * 1000)
            },
            isUpperHalfHit: isUpperHalfHit
        )
    }

    /// Projection where Y and Z share most of their screen direction, so a
    /// vertical pinch picks Y but with high ambiguity — forcing the
    /// upper-half hit-test fallback.
    private static func ambiguousYProjection(
        isUpperHalfHit: @escaping (CGPoint) -> Bool
    ) -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { world in
                CGPoint(
                    x: CGFloat(world.x) * 1000,
                    y: CGFloat(-world.y - 0.95 * world.z) * 1000
                )
            },
            isUpperHalfHit: isUpperHalfHit
        )
    }

    private static func makeBeginInput(
        fingers: (first: CGPoint, second: CGPoint)
    ) -> ParcelResizeInteraction.BeginInput {
        ParcelResizeInteraction.BeginInput(
            cuboidPosition: initialPosition,
            cuboidScale: initialScale,
            cuboidYaw: 0,
            fingers: fingers
        )
    }

    // MARK: - Lifecycle

    @Test func test_isActive_when_interaction_is_fresh_then_returns_false() {
        // Given
        let interaction = ParcelResizeInteraction()

        // Then
        #expect(!interaction.isActive)
        #expect(interaction.highlightedFaces.isEmpty)
    }

    @Test func test_end_when_called_after_begin_then_clears_state() {
        // Given
        let interaction = ParcelResizeInteraction()
        let input = Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))
        interaction.begin(input: input, environment: Self.linearProjection())
        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveX, .negativeX])

        // When
        interaction.end()

        // Then
        #expect(!interaction.isActive)
        #expect(interaction.highlightedFaces.isEmpty)
    }

    // MARK: - Begin

    @Test func test_begin_when_Y_pick_is_ambiguous_and_no_upper_half_hit_then_does_not_activate() {
        // Given
        let interaction = ParcelResizeInteraction()
        let input = Self.makeBeginInput(fingers: (CGPoint(x: 0, y: 100), CGPoint(x: 0, y: -100)))

        // When
        interaction.begin(input: input, environment: Self.ambiguousYProjection(isUpperHalfHit: { _ in false }))

        // Then
        #expect(!interaction.isActive)
    }

    @Test func test_begin_when_Y_pick_is_ambiguous_and_finger_hits_upper_half_then_activates_on_Y() {
        // Given
        let interaction = ParcelResizeInteraction()
        let upperFinger = CGPoint(x: 0, y: -100)
        let lowerFinger = CGPoint(x: 0, y: 100)
        let input = Self.makeBeginInput(fingers: (upperFinger, lowerFinger))

        // When
        interaction.begin(input: input, environment: Self.ambiguousYProjection(isUpperHalfHit: { point in
            point == upperFinger
        }))

        // Then
        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveY, .negativeY])
    }

    // MARK: - Update

    @Test func test_update_when_called_before_begin_then_returns_nil() {
        // Given
        let interaction = ParcelResizeInteraction()

        // When
        let result = interaction.update(
            fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)),
            environment: Self.linearProjection()
        )

        // Then
        #expect(result == nil)
    }

    @Test func test_update_when_finger_motion_is_below_jitter_threshold_then_returns_nil() {
        // Given
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        // When
        let result = interaction.update(
            fingers: (CGPoint(x: -50.5, y: 0), CGPoint(x: 50.5, y: 0)),
            environment: env
        )

        // Then
        #expect(result == nil)
    }

    @Test func test_update_when_pinch_is_symmetric_then_grows_axis_without_shifting_position() throws {
        // Given
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        // When
        // Each finger moves outward by 50 screen units = 0.05 world units, so
        // total axis growth = 0.1 metres.
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: -100, y: 0), CGPoint(x: 100, y: 0)),
            environment: env
        ))

        // Then
        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.scale.y, Self.initialScale.y))
        #expect(approxEqual(output.scale.z, Self.initialScale.z))
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }

    @Test func test_update_when_shrinking_past_floor_then_clamps_to_minimum_size() throws {
        // Given
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -200, y: 0), CGPoint(x: 200, y: 0))),
            environment: env
        )

        // When
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)),
            environment: env
        ))

        // Then
        #expect(approxEqual(output.scale.x, ParcelResizeInteraction.Constants.minSizeMeters))
    }

    @Test func test_update_when_X_axis_move_is_asymmetric_then_shifts_position_by_half_the_imbalance() throws {
        // Given
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        // When
        // Only the +X finger moves outward by 0.1 m. Outward grows by 0.1,
        // total scale grows by 0.1, root shifts +0.05.
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 150, y: 0)),
            environment: env
        ))

        // Then
        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.position.x, Self.initialPosition.x + 0.05))
    }

    @Test func test_update_when_Y_axis_resizes_then_position_does_not_shift() throws {
        // Given
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: 0, y: -50), CGPoint(x: 0, y: 50))),
            environment: env
        )
        #expect(interaction.highlightedFaces == [.positiveY, .negativeY])

        // When
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: 0, y: -200), CGPoint(x: 0, y: 50)),
            environment: env
        ))

        // Then
        #expect(output.scale.y > Self.initialScale.y)
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.y, Self.initialPosition.y))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }
}

private func approxEqual(_ a: Float, _ b: Float, tolerance: Float = 1e-4) -> Bool {
    abs(a - b) < tolerance
}
