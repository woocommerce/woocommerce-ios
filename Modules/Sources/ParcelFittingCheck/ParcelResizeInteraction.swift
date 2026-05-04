import CoreGraphics
import Foundation
import simd

/// Pure state machine for the two-finger resize interaction.
///
/// Takes a snapshot of scene state plus screen/plane projection callbacks and
/// returns the new transform — no `ARView` access, no scene side effects. The
/// coordinator is responsible for taking the snapshot, applying the output,
/// and emitting callbacks. This separation lets the resize math be unit-tested
/// without ARKit.
final class ParcelResizeInteraction {
    struct Input {
        var cuboidPosition: SIMD3<Float>
        var cuboidScale: SIMD3<Float>
        var cuboidYaw: Float
        var cameraForward: SIMD3<Float>
        var fingers: (first: CGPoint, second: CGPoint)
    }

    struct Output {
        var scale: SIMD3<Float>
        var position: SIMD3<Float>
    }

    struct Environment {
        var projectToScreen: (SIMD3<Float>) -> CGPoint?
        var projectToPlane: (_ screen: CGPoint, _ planePoint: SIMD3<Float>, _ planeNormal: SIMD3<Float>) -> SIMD3<Float>?
        var isUpperHalfHit: (_ screen: CGPoint) -> Bool
    }

    /// Per-frame screen-space dead zone, in points. Below this, finger movement
    /// is treated as touch-sensor jitter and the resize update is skipped.
    static let jitterThresholdPoints: CGFloat = 1.5

    /// Minimum allowed cuboid size on any axis, in metres.
    static let minSizeMeters: Float = 0.02

    /// When Y wins the screen-space alignment race, an X or Z axis whose
    /// screen direction is close to Y's is a plausible alternative; below this
    /// ratio (second-best / best) Y is the clear winner and the hit-test is
    /// skipped. 0.7 ≈ ~45° of screen-direction separation.
    static let yAxisAmbiguityThreshold: Float = 0.7

    private struct FingerLatch {
        let face: ARCuboidEntity.Face
        let initialAxisDisplacement: Float
    }

    private struct ResizeContext {
        let axis: ARCuboidEntity.Axis
        let axisWorld: SIMD3<Float>
        let cuboidCenterAtStart: SIMD3<Float>
        let planeNormal: SIMD3<Float>
        let initialScale: SIMD3<Float>
        let initialPosition: SIMD3<Float>
        let firstFinger: FingerLatch
        let secondFinger: FingerLatch
    }

    private var context: ResizeContext?
    private var lastFingers: (first: CGPoint, second: CGPoint)?

    var isActive: Bool { context != nil }

    var highlightedFaces: Set<ARCuboidEntity.Face> {
        guard let context else { return [] }
        return [context.firstFinger.face, context.secondFinger.face]
    }

    /// Initialise the resize state from the gesture's start positions. After
    /// this call, `update` will produce transforms; without it, `update`
    /// returns `nil`. May fail silently (no axis pick, missed Y hit-test,
    /// projection failure) — the caller can retry on the next frame.
    func begin(input: Input, environment env: Environment) {
        let axes = localAxes(yaw: input.cuboidYaw)
        // Cuboid local Y is 0…1 with the root at the floor, so the geometric
        // centre sits half-a-height up.
        let cuboidCenter = input.cuboidPosition + 0.5 * input.cuboidScale.y * axes.y

        guard let pick = pickActiveAxis(
            cuboidCenter: cuboidCenter,
            axes: axes,
            firstScreen: input.fingers.first,
            secondScreen: input.fingers.second,
            environment: env
        ) else { return }

        // For Y, a vertical screen-space pinch is the natural cue. We accept
        // it without a hit-test when Y dominates; only when X or Z projects
        // close to Y's screen direction do we fall back to requiring at least
        // one finger on the upper half of the cuboid.
        if pick.axis == .y && pick.ambiguity > Self.yAxisAmbiguityThreshold {
            let firstUpper = env.isUpperHalfHit(input.fingers.first)
            let secondUpper = env.isUpperHalfHit(input.fingers.second)
            guard firstUpper || secondUpper else { return }
        }

        let axisWorld = axes[pick.axis]

        guard let hit0 = env.projectToPlane(input.fingers.first, cuboidCenter, input.cameraForward),
              let hit1 = env.projectToPlane(input.fingers.second, cuboidCenter, input.cameraForward) else { return }

        let disp0 = simd_dot(hit0 - cuboidCenter, axisWorld)
        let disp1 = simd_dot(hit1 - cuboidCenter, axisWorld)
        // The finger with the larger axis projection drives the +face and the
        // other drives the -face, even when both fingers are on the same side
        // of the cuboid centre.
        let firstIsPositive = disp0 >= disp1

        let firstLatch = FingerLatch(
            face: firstIsPositive ? .positiveSide(of: pick.axis) : .negativeSide(of: pick.axis),
            initialAxisDisplacement: disp0
        )
        let secondLatch = FingerLatch(
            face: firstIsPositive ? .negativeSide(of: pick.axis) : .positiveSide(of: pick.axis),
            initialAxisDisplacement: disp1
        )

        context = ResizeContext(
            axis: pick.axis,
            axisWorld: axisWorld,
            cuboidCenterAtStart: cuboidCenter,
            planeNormal: input.cameraForward,
            initialScale: input.cuboidScale,
            initialPosition: input.cuboidPosition,
            firstFinger: firstLatch,
            secondFinger: secondLatch
        )
        lastFingers = input.fingers
    }

    /// Apply gesture motion to the resize. Returns the new scale/position to
    /// commit, or `nil` if the change should be skipped (jitter, missing
    /// context, projection failure).
    func update(input: Input, environment env: Environment) -> Output? {
        guard let context else { return nil }

        if let last = lastFingers {
            let firstDelta = hypot(input.fingers.first.x - last.first.x, input.fingers.first.y - last.first.y)
            let secondDelta = hypot(input.fingers.second.x - last.second.x, input.fingers.second.y - last.second.y)
            if firstDelta < Self.jitterThresholdPoints && secondDelta < Self.jitterThresholdPoints {
                return nil
            }
        }

        guard let hit0 = env.projectToPlane(input.fingers.first, context.cuboidCenterAtStart, context.planeNormal),
              let hit1 = env.projectToPlane(input.fingers.second, context.cuboidCenterAtStart, context.planeNormal) else { return nil }

        let disp0 = simd_dot(hit0 - context.cuboidCenterAtStart, context.axisWorld)
        let disp1 = simd_dot(hit1 - context.cuboidCenterAtStart, context.axisWorld)

        let firstAxisDelta = disp0 - context.firstFinger.initialAxisDisplacement
        let secondAxisDelta = disp1 - context.secondFinger.initialAxisDisplacement
        let firstOutward = signedOutwardDelta(face: context.firstFinger.face, axisDelta: firstAxisDelta)
        let secondOutward = signedOutwardDelta(face: context.secondFinger.face, axisDelta: secondAxisDelta)

        let outwardPositive: Float
        let outwardNegative: Float
        if context.firstFinger.face.isPositiveSide {
            outwardPositive = firstOutward
            outwardNegative = secondOutward
        } else {
            outwardPositive = secondOutward
            outwardNegative = firstOutward
        }

        let axisIndex = simdIndex(for: context.axis)
        let oldAxisScale = context.initialScale[axisIndex]
        let totalDelta = outwardPositive + outwardNegative
        let newAxisScale = max(oldAxisScale + totalDelta, Self.minSizeMeters)

        // When the user shrinks past the floor, scale per-finger contributions
        // back proportionally so the centre tracks both fingers smoothly (the
        // cuboid stops shrinking but does not jump).
        let actualTotal = newAxisScale - oldAxisScale
        let scaleFactor: Float = abs(totalDelta) < 1e-6 ? 1 : actualTotal / totalDelta
        let actualPositive = outwardPositive * scaleFactor
        let actualNegative = outwardNegative * scaleFactor

        var newScale = context.initialScale
        newScale[axisIndex] = newAxisScale

        var newPosition = context.initialPosition
        // Y axis keeps the root at the floor (cuboid local Y is 0…1, so growing
        // scale.y already moves only the top). X/Z are root-centred, so an
        // asymmetric resize requires shifting the root by half the imbalance.
        // The cap |shift| ≤ |scale change| / 2 prevents pure translation: when
        // both fingers move in the same direction, scale stays put and the cap
        // collapses to zero, so the cuboid does not slide.
        if context.axis != .y {
            let centerShift = (actualPositive - actualNegative) * 0.5
            let maxShift = abs(actualTotal) * 0.5
            let clampedShift = max(-maxShift, min(maxShift, centerShift))
            newPosition += clampedShift * context.axisWorld
        }

        lastFingers = input.fingers
        return Output(scale: newScale, position: newPosition)
    }

    func end() {
        context = nil
        lastFingers = nil
    }
}

private extension ParcelResizeInteraction {
    struct LocalAxes {
        let x: SIMD3<Float>
        let y: SIMD3<Float>
        let z: SIMD3<Float>

        subscript(axis: ARCuboidEntity.Axis) -> SIMD3<Float> {
            switch axis {
            case .x: return x
            case .y: return y
            case .z: return z
            }
        }
    }

    func localAxes(yaw: Float) -> LocalAxes {
        LocalAxes(
            x: SIMD3(cos(yaw), 0, -sin(yaw)),
            y: SIMD3(0, 1, 0),
            z: SIMD3(sin(yaw), 0, cos(yaw))
        )
    }

    func pickActiveAxis(
        cuboidCenter: SIMD3<Float>,
        axes: LocalAxes,
        firstScreen: CGPoint,
        secondScreen: CGPoint,
        environment env: Environment
    ) -> (axis: ARCuboidEntity.Axis, ambiguity: Float)? {
        guard let centerScreen = env.projectToScreen(cuboidCenter),
              let xEnd = env.projectToScreen(cuboidCenter + 0.1 * axes.x),
              let yEnd = env.projectToScreen(cuboidCenter + 0.1 * axes.y),
              let zEnd = env.projectToScreen(cuboidCenter + 0.1 * axes.z) else { return nil }

        let xDir = CGPoint(x: xEnd.x - centerScreen.x, y: xEnd.y - centerScreen.y)
        let yDir = CGPoint(x: yEnd.x - centerScreen.x, y: yEnd.y - centerScreen.y)
        let zDir = CGPoint(x: zEnd.x - centerScreen.x, y: zEnd.y - centerScreen.y)
        let fingerDir = CGPoint(x: secondScreen.x - firstScreen.x, y: secondScreen.y - firstScreen.y)

        let candidates: [(ARCuboidEntity.Axis, CGPoint)] = [(.x, xDir), (.y, yDir), (.z, zDir)]
        var bestAxis: ARCuboidEntity.Axis?
        var bestScore: CGFloat = 0
        var secondBestScore: CGFloat = 0
        for (axis, dir) in candidates {
            let length = max(hypot(dir.x, dir.y), 1)
            let score = abs(fingerDir.x * dir.x + fingerDir.y * dir.y) / length
            if score > bestScore {
                secondBestScore = bestScore
                bestScore = score
                bestAxis = axis
            } else if score > secondBestScore {
                secondBestScore = score
            }
        }
        guard let bestAxis else { return nil }
        let ambiguity: Float = bestScore > 0 ? Float(secondBestScore / bestScore) : 0
        return (bestAxis, ambiguity)
    }

    func signedOutwardDelta(face: ARCuboidEntity.Face, axisDelta: Float) -> Float {
        if face == .negativeY { return 0 }
        return face.isPositiveSide ? axisDelta : -axisDelta
    }

    func simdIndex(for axis: ARCuboidEntity.Axis) -> Int {
        switch axis {
        case .x: return 0
        case .y: return 1
        case .z: return 2
        }
    }
}
