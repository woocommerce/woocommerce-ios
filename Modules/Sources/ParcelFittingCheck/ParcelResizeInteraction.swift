import CoreGraphics
import Foundation
import simd

/// Pure state machine for the two-finger resize interaction.
final class ParcelResizeInteraction {
    struct BeginInput {
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

    enum Constants {
        /// Minimum allowed cuboid size on any axis, in metres.
        static let minSizeMeters: Float = 0.02

        /// Per-frame screen-space dead zone, in points. Below this, finger
        /// movement is treated as touch-sensor jitter and the resize update
        /// is skipped.
        static let jitterThresholdPoints: CGFloat = 1.5

        /// When Y wins the screen-space alignment race, an X or Z axis whose
        /// screen direction is close to Y's is a plausible alternative; below
        /// this ratio (second-best / best) Y is the clear winner and the
        /// hit-test is skipped. 0.7 ≈ ~45° of screen-direction separation.
        static let yAxisAmbiguityThreshold: Float = 0.7

        /// Distance, in metres, of the axis probe from the cuboid centre when
        /// projecting world-space axes into screen space for the pinch
        /// direction match.
        static let axisProbeDistance: Float = 0.1

        /// Numerical-stability epsilon for divide-by-zero guards.
        static let nearZeroEpsilon: Float = 1e-6

        /// Floor for screen-direction lengths to avoid divide-by-zero when
        /// scoring the axis pick.
        static let minScreenDirectionLength: CGFloat = 1
    }

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

    /// May fail silently (no axis pick, missed Y hit-test, projection failure);
    /// the caller can retry on the next gesture frame.
    func begin(input: BeginInput, environment env: Environment) {
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
        if pick.axis == .y && pick.ambiguity > Constants.yAxisAmbiguityThreshold {
            let firstUpper = env.isUpperHalfHit(input.fingers.first)
            let secondUpper = env.isUpperHalfHit(input.fingers.second)
            guard firstUpper || secondUpper else { return }
        }

        let axisWorld = axes[pick.axis]

        guard let (disp0, disp1) = axisDisplacements(
            fingers: input.fingers,
            planePoint: cuboidCenter,
            planeNormal: input.cameraForward,
            axisWorld: axisWorld,
            environment: env
        ) else { return }

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

    /// Returns the new scale/position to commit, or `nil` if the change should
    /// be skipped (jitter, missing context, projection failure).
    func update(fingers: (first: CGPoint, second: CGPoint), environment env: Environment) -> Output? {
        guard let context else { return nil }

        if let last = lastFingers {
            let firstDelta = hypot(fingers.first.x - last.first.x, fingers.first.y - last.first.y)
            let secondDelta = hypot(fingers.second.x - last.second.x, fingers.second.y - last.second.y)
            if firstDelta < Constants.jitterThresholdPoints && secondDelta < Constants.jitterThresholdPoints {
                return nil
            }
        }

        guard let (disp0, disp1) = axisDisplacements(
            fingers: fingers,
            planePoint: context.cuboidCenterAtStart,
            planeNormal: context.planeNormal,
            axisWorld: context.axisWorld,
            environment: env
        ) else { return nil }

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

        let axisIndex = context.axis.simdIndex
        let oldAxisScale = context.initialScale[axisIndex]
        let totalDelta = outwardPositive + outwardNegative
        let newAxisScale = max(oldAxisScale + totalDelta, Constants.minSizeMeters)

        // When the user shrinks past the floor, scale per-finger contributions
        // back proportionally so the centre tracks both fingers smoothly (the
        // cuboid stops shrinking but does not jump).
        let actualTotal = newAxisScale - oldAxisScale
        let scaleFactor: Float = abs(totalDelta) < Constants.nearZeroEpsilon ? 1 : actualTotal / totalDelta
        let actualPositive = outwardPositive * scaleFactor
        let actualNegative = outwardNegative * scaleFactor

        var newScale = context.initialScale
        newScale[axisIndex] = newAxisScale

        var newPosition = context.initialPosition
        // X/Z are root-centred, so an asymmetric resize requires shifting the
        // root by half the imbalance. The cap |shift| ≤ |scale change| / 2
        // collapses to zero when both fingers move the same direction, so the
        // cuboid does not slide — single-finger drag is the only sanctioned
        // way to translate. Y is anchored at the floor and never shifts.
        if context.axis != .y {
            let centerShift = (actualPositive - actualNegative) * 0.5
            let maxShift = abs(actualTotal) * 0.5
            let clampedShift = max(-maxShift, min(maxShift, centerShift))
            newPosition += clampedShift * context.axisWorld
        }

        lastFingers = fingers
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
              let xEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.x),
              let yEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.y),
              let zEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.z) else { return nil }

        let xDir = CGPoint(x: xEnd.x - centerScreen.x, y: xEnd.y - centerScreen.y)
        let yDir = CGPoint(x: yEnd.x - centerScreen.x, y: yEnd.y - centerScreen.y)
        let zDir = CGPoint(x: zEnd.x - centerScreen.x, y: zEnd.y - centerScreen.y)
        let fingerDir = CGPoint(x: secondScreen.x - firstScreen.x, y: secondScreen.y - firstScreen.y)

        let candidates: [(ARCuboidEntity.Axis, CGPoint)] = [(.x, xDir), (.y, yDir), (.z, zDir)]
        var bestAxis: ARCuboidEntity.Axis?
        var bestScore: CGFloat = 0
        var secondBestScore: CGFloat = 0
        for (axis, dir) in candidates {
            let length = max(hypot(dir.x, dir.y), Constants.minScreenDirectionLength)
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

    func axisDisplacements(
        fingers: (first: CGPoint, second: CGPoint),
        planePoint: SIMD3<Float>,
        planeNormal: SIMD3<Float>,
        axisWorld: SIMD3<Float>,
        environment env: Environment
    ) -> (Float, Float)? {
        guard let hit0 = env.projectToPlane(fingers.first, planePoint, planeNormal),
              let hit1 = env.projectToPlane(fingers.second, planePoint, planeNormal) else { return nil }
        return (
            simd_dot(hit0 - planePoint, axisWorld),
            simd_dot(hit1 - planePoint, axisWorld)
        )
    }

    func signedOutwardDelta(face: ARCuboidEntity.Face, axisDelta: Float) -> Float {
        if face == .negativeY { return 0 }
        return face.isPositiveSide ? axisDelta : -axisDelta
    }
}
