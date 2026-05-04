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

    /// Projection that picks X horizontally, Y vertically and ignores Z, so an
    /// X-axis pinch (horizontal fingers) is the unambiguous winner.
    private static func xAxisProjection() -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { world in
                CGPoint(x: CGFloat(world.x) * 1000, y: CGFloat(-world.y) * 1000)
            },
            projectToPlane: planeProjection(),
            isUpperHalfHit: { _ in false }
        )
    }

    /// Projection where Y dominates strongly and X/Z share screen direction
    /// with each other but not Y. Used for unambiguous Y picks.
    private static func yAxisProjection(isUpperHalfHit: @escaping (CGPoint) -> Bool = { _ in false }) -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { world in
                CGPoint(x: CGFloat(world.x) * 1000, y: CGFloat(-world.y) * 1000)
            },
            projectToPlane: planeProjection(),
            isUpperHalfHit: isUpperHalfHit
        )
    }

    /// Projection where Y and Z are nearly parallel on screen. A vertical
    /// pinch will pick Y, but ambiguity > threshold, forcing the upper-half
    /// hit-test fallback.
    private static func ambiguousYProjection(isUpperHalfHit: @escaping (CGPoint) -> Bool) -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { world in
                // Y → vertical, Z → also mostly vertical (close enough to make
                // the pick ambiguous). X stays horizontal.
                CGPoint(
                    x: CGFloat(world.x) * 1000,
                    y: CGFloat(-world.y - 0.95 * world.z) * 1000
                )
            },
            projectToPlane: planeProjection(),
            isUpperHalfHit: isUpperHalfHit
        )
    }

    /// Plane projection that treats the screen point as world XY at the
    /// plane's depth. Sufficient for tests where planeNormal = (0, 0, -1).
    private static func planeProjection() -> (CGPoint, SIMD3<Float>, SIMD3<Float>) -> SIMD3<Float>? {
        { screen, planePoint, _ in
            SIMD3(Float(screen.x) / 1000, Float(-screen.y) / 1000, planePoint.z)
        }
    }

    private static func makeInput(fingers: (first: CGPoint, second: CGPoint)) -> ParcelResizeInteraction.Input {
        ParcelResizeInteraction.Input(
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
        let input = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))

        interaction.begin(input: input, environment: Self.xAxisProjection())
        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveX, .negativeX])

        interaction.end()
        #expect(!interaction.isActive)
        #expect(interaction.highlightedFaces.isEmpty)
    }

    // MARK: - Begin

    @Test("begin succeeds for an unambiguous X-axis pinch")
    func begin_succeeds_forUnambiguousXPinch() {
        let interaction = ParcelResizeInteraction()
        let input = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))

        interaction.begin(input: input, environment: Self.xAxisProjection())

        #expect(interaction.isActive)
        #expect(interaction.highlightedFaces == [.positiveX, .negativeX])
    }

    @Test("begin requires an upper-half hit-test when Y pick is ambiguous")
    func begin_requiresUpperHalfHit_whenYIsAmbiguous() {
        let interaction = ParcelResizeInteraction()
        let input = Self.makeInput(fingers: (CGPoint(x: 0, y: 100), CGPoint(x: 0, y: -100)))

        // Neither finger is on the upper half — begin should bail out.
        interaction.begin(input: input, environment: Self.ambiguousYProjection(isUpperHalfHit: { _ in false }))

        #expect(!interaction.isActive)
    }

    @Test("begin proceeds when Y is ambiguous but a finger hits the upper half")
    func begin_proceeds_whenYIsAmbiguous_withUpperHalfHit() {
        let interaction = ParcelResizeInteraction()
        let upperFinger = CGPoint(x: 0, y: -100)
        let lowerFinger = CGPoint(x: 0, y: 100)
        let input = Self.makeInput(fingers: (upperFinger, lowerFinger))

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
        let input = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))

        #expect(interaction.update(input: input, environment: Self.xAxisProjection()) == nil)
    }

    @Test("update skips sub-jitter motion")
    func update_skips_subJitterMotion() {
        let interaction = ParcelResizeInteraction()
        let env = Self.xAxisProjection()
        let start = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))
        interaction.begin(input: start, environment: env)

        let jittered = Self.makeInput(fingers: (
            CGPoint(x: -50.5, y: 0),
            CGPoint(x: 50.5, y: 0)
        ))

        #expect(interaction.update(input: jittered, environment: env) == nil)
    }

    @Test("symmetric outward pinch grows the chosen axis without shifting position")
    func update_grows_axis_onSymmetricPinch() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.xAxisProjection()
        let start = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))
        interaction.begin(input: start, environment: env)

        // Each finger moves outward by 50 screen units = 0.05 world units, so
        // total axis growth = 0.1 metres.
        let moved = Self.makeInput(fingers: (CGPoint(x: -100, y: 0), CGPoint(x: 100, y: 0)))
        let output = try #require(interaction.update(input: moved, environment: env))

        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.scale.y, Self.initialScale.y))
        #expect(approxEqual(output.scale.z, Self.initialScale.z))
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }

    @Test("update clamps to minimum size when shrinking past floor")
    func update_clampsToMinimum_whenShrinkingPastFloor() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.xAxisProjection()
        let start = Self.makeInput(fingers: (CGPoint(x: -200, y: 0), CGPoint(x: 200, y: 0)))
        interaction.begin(input: start, environment: env)

        // Pinch fingers all the way together — way past the 0.02 m floor.
        let moved = Self.makeInput(fingers: (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)))
        let output = try #require(interaction.update(input: moved, environment: env))

        #expect(approxEqual(output.scale.x, ParcelResizeInteraction.minSizeMeters))
    }

    @Test("asymmetric X-axis move shifts position by half the imbalance")
    func update_shiftsPosition_onAsymmetricXMove() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.xAxisProjection()
        let start = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0)))
        interaction.begin(input: start, environment: env)

        // Only the +X finger moves outward by 0.1 m. The -X finger stays.
        // Outward grows by 0.1, total scale grows by 0.1, root shifts +0.05.
        let moved = Self.makeInput(fingers: (CGPoint(x: -50, y: 0), CGPoint(x: 150, y: 0)))
        let output = try #require(interaction.update(input: moved, environment: env))

        #expect(approxEqual(output.scale.x, Self.initialScale.x + 0.1))
        #expect(approxEqual(output.position.x, Self.initialPosition.x + 0.05))
    }

    @Test("Y-axis resize never shifts position")
    func update_doesNotShiftPosition_onYResize() throws {
        let interaction = ParcelResizeInteraction()
        let env = Self.yAxisProjection()
        let start = Self.makeInput(fingers: (CGPoint(x: 0, y: -50), CGPoint(x: 0, y: 50)))
        interaction.begin(input: start, environment: env)
        #expect(interaction.highlightedFaces == [.positiveY, .negativeY])

        // Stretch only the upper finger upward. Y should grow but position
        // must stay put — the cuboid root is anchored at the floor.
        let moved = Self.makeInput(fingers: (CGPoint(x: 0, y: -200), CGPoint(x: 0, y: 50)))
        let output = try #require(interaction.update(input: moved, environment: env))

        #expect(output.scale.y > Self.initialScale.y)
        #expect(approxEqual(output.position.x, Self.initialPosition.x))
        #expect(approxEqual(output.position.y, Self.initialPosition.y))
        #expect(approxEqual(output.position.z, Self.initialPosition.z))
    }
}

private func approxEqual(_ a: Float, _ b: Float, tolerance: Float = 1e-4) -> Bool {
    abs(a - b) < tolerance
}
