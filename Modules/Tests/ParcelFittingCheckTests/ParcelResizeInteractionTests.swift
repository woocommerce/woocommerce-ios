import CoreGraphics
import Testing
import simd
@testable import ParcelFittingCheck

@Suite("ParcelResizeInteraction")
struct ParcelResizeInteractionTests {

    // MARK: - Fixtures

    private static let initialPosition = SIMD3<Float>(0, 0, 0)
    private static let initialScale = SIMD3<Float>(0.20, 0.10, 0.15)
    private static let cameraForward = SIMD3<Float>(0, 0, -1)

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
            projectToPlane: { screen, planePoint, _ in
                SIMD3(Float(screen.x) / 1000, Float(-screen.y) / 1000, planePoint.z)
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
            projectToPlane: { screen, planePoint, _ in
                SIMD3(Float(screen.x) / 1000, Float(-screen.y) / 1000, planePoint.z)
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
            cameraForward: cameraForward,
            fingers: fingers
        )
    }

    // MARK: - Lifecycle

    @Test("isActive is false before begin")
    func isActive_isFalse_beforeBegin() {
        let interaction = ParcelResizeInteraction()
        #expect(!interaction.isActive)
        #expect(interaction.highlightedFaces.isEmpty)
    }

    @Test("begin then end resets state")
    func begin_then_end_resetsState() {
        let interaction = ParcelResizeInteraction()
        let input = Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))

        interaction.begin(input: input, environment: Self.linearProjection())
        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveX, .negativeX])

        interaction.end()
        #expect(!interaction.isActive)
        #expect(interaction.highlightedFaces.isEmpty)
    }

    // MARK: - Begin

    @Test("begin requires an upper-half hit-test when Y pick is ambiguous")
    func begin_requiresUpperHalfHit_whenYIsAmbiguous() {
        let interaction = ParcelResizeInteraction()
        let input = Self.makeBeginInput(fingers: (CGPoint(x: 0, y: 100), CGPoint(x: 0, y: -100)))

        interaction.begin(input: input, environment: Self.ambiguousYProjection(isUpperHalfHit: { _ in false }))

        #expect(!interaction.isActive)
    }

    @Test("begin proceeds when Y is ambiguous but a finger hits the upper half")
    func begin_proceeds_whenYIsAmbiguous_withUpperHalfHit() {
        let interaction = ParcelResizeInteraction()
        let upperFinger = CGPoint(x: 0, y: -100)
        let lowerFinger = CGPoint(x: 0, y: 100)
        let input = Self.makeBeginInput(fingers: (upperFinger, lowerFinger))

        interaction.begin(input: input, environment: Self.ambiguousYProjection(isUpperHalfHit: { point in
            point == upperFinger
        }))

        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveY, .negativeY])
    }

    // MARK: - Update

    @Test("update returns nil before begin")
    func update_returnsNil_beforeBegin() {
        let interaction = ParcelResizeInteraction()
        let result = interaction.update(
            fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)),
            environment: Self.linearProjection()
        )
        #expect(result == nil)
    }

    @Test("update skips sub-jitter motion")
    func update_skips_subJitterMotion() {
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        let result = interaction.update(
            fingers: (CGPoint(x: -50.5, y: 0), CGPoint(x: 50.5, y: 0)),
            environment: env
        )

        #expect(result == nil)
    }

    @Test("symmetric outward pinch grows the chosen axis without shifting position")
    func update_grows_axis_onSymmetricPinch() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        // Each finger moves outward by 50 screen units = 0.05 world units, so
        // total axis growth = 0.1 metres.
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: -100, y: 0), CGPoint(x: 100, y: 0)),
            environment: env
        ))

        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.scale.y, Self.initialScale.y))
        #expect(approxEqual(output.scale.z, Self.initialScale.z))
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }

    @Test("update clamps to minimum size when shrinking past floor")
    func update_clampsToMinimum_whenShrinkingPastFloor() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -200, y: 0), CGPoint(x: 200, y: 0))),
            environment: env
        )

        let output = try #require(interaction.update(
            fingers: (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)),
            environment: env
        ))

        #expect(approxEqual(output.scale.x, ParcelResizeInteraction.minSizeMeters))
    }

    @Test("asymmetric X-axis move shifts position by half the imbalance")
    func update_shiftsPosition_onAsymmetricXMove() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0))),
            environment: env
        )

        // Only the +X finger moves outward by 0.1 m. Outward grows by 0.1,
        // total scale grows by 0.1, root shifts +0.05.
        let output = try #require(interaction.update(
            fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 150, y: 0)),
            environment: env
        ))

        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.position.x, Self.initialPosition.x + 0.05))
    }

    @Test("Y-axis resize never shifts position")
    func update_doesNotShiftPosition_onYResize() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.linearProjection()
        interaction.begin(
            input: Self.makeBeginInput(fingers: (CGPoint(x: 0, y: -50), CGPoint(x: 0, y: 50))),
            environment: env
        )
        #expect(interaction.highlightedFaces == [.positiveY, .negativeY])

        let output = try #require(interaction.update(
            fingers: (CGPoint(x: 0, y: -200), CGPoint(x: 0, y: 50)),
            environment: env
        ))

        #expect(output.scale.y > Self.initialScale.y)
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.y, Self.initialPosition.y))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }
}

private func approxEqual(_ a: Float, _ b: Float, tolerance: Float = 1e-4) -> Bool {
    abs(a - b) < tolerance
}
