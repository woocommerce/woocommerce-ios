import CoreGraphics
import Foundation
import simd

/// Pure state machine for the two-finger resize interaction.
final class ParcelResizeInteraction {
    struct BeginInput {
        var cuboidPosition: SIMD3<Float>
        var cuboidScale: SIMD3<Float>
        var cuboidYaw: Float
        var fingers: (first: CGPoint, second: CGPoint)
    }

    struct Output {
        var scale: SIMD3<Float>
        var position: SIMD3<Float>
    }

    struct Environment {
        var projectToScreen: (SIMD3<Float>) -> CGPoint?
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
        let initialScreen: CGPoint
    }

    private struct ResizeContext {
        let axis: ARCuboidEntity.Axis
        let axisWorld: SIMD3<Float>
        /// Unit vector along `axis` projected into screen space at gesture
        /// start. Multiplied by `pixelsPerMeter`, it converts screen-pixel
        /// movement along this direction into world-axis metres.
        let axisScreenUnit: CGPoint
        let pixelsPerMeter: CGFloat
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

        guard let projection = projectAxes(cuboidCenter: cuboidCenter, axes: axes, environment: env) else {
            return
        }
        let pick = pickActiveAxis(
            projection: projection,
            firstScreen: input.fingers.first,
            secondScreen: input.fingers.second
        )
        guard let pick else {
            return
        }

        // For Y, a vertical screen-space pinch is the natural cue. We accept
        // it without a hit-test when Y dominates; only when X or Z projects
        // close to Y's screen direction do we fall back to requiring at least
        // one finger on the upper half of the cuboid.
        if pick.axis == .y && pick.ambiguity > Constants.yAxisAmbiguityThreshold {
            let firstUpper = env.isUpperHalfHit(input.fingers.first)
            let secondUpper = env.isUpperHalfHit(input.fingers.second)
            guard firstUpper || secondUpper else {
                return
            }
        }

        let axisScreenVec = projection.axisVector(for: pick.axis)
        let length = hypot(axisScreenVec.x, axisScreenVec.y)
        guard length > Constants.minScreenDirectionLength else {
            return
        }
        let axisScreenUnit = CGPoint(x: axisScreenVec.x / length, y: axisScreenVec.y / length)
        let pixelsPerMeter = length / CGFloat(Constants.axisProbeDistance)

        // Score each finger's signed screen offset along the axis to decide
        // which drives the +face vs the −face (the larger projection drives
        // +face), even when both fingers are on the same side of the cuboid.
        let firstAxisOffset = signedOffset(input.fingers.first, from: projection.center, along: axisScreenUnit)
        let secondAxisOffset = signedOffset(input.fingers.second, from: projection.center, along: axisScreenUnit)
        let firstIsPositive = firstAxisOffset >= secondAxisOffset

        let firstLatch = FingerLatch(
            face: ARCuboidEntity.Face(axis: pick.axis, isPositiveSide: firstIsPositive),
            initialScreen: input.fingers.first
        )
        let secondLatch = FingerLatch(
            face: ARCuboidEntity.Face(axis: pick.axis, isPositiveSide: !firstIsPositive),
            initialScreen: input.fingers.second
        )

        context = ResizeContext(
            axis: pick.axis,
            axisWorld: axes[pick.axis],
            axisScreenUnit: axisScreenUnit,
            pixelsPerMeter: pixelsPerMeter,
            initialScale: input.cuboidScale,
            initialPosition: input.cuboidPosition,
            firstFinger: firstLatch,
            secondFinger: secondLatch
        )
        lastFingers = input.fingers
    }

    /// Returns the new scale/position to commit, or `nil` if the change should
    /// be skipped (jitter, missing context).
    func update(fingers: (first: CGPoint, second: CGPoint), environment env: Environment) -> Output? {
        guard let context else { return nil }

        if let last = lastFingers {
            let firstFrameDelta = hypot(fingers.first.x - last.first.x, fingers.first.y - last.first.y)
            let secondFrameDelta = hypot(fingers.second.x - last.second.x, fingers.second.y - last.second.y)
            if firstFrameDelta < Constants.jitterThresholdPoints && secondFrameDelta < Constants.jitterThresholdPoints {
                return nil
            }
        }

        let firstScreenDelta = CGPoint(
            x: fingers.first.x - context.firstFinger.initialScreen.x,
            y: fingers.first.y - context.firstFinger.initialScreen.y
        )
        let secondScreenDelta = CGPoint(
            x: fingers.second.x - context.secondFinger.initialScreen.x,
            y: fingers.second.y - context.secondFinger.initialScreen.y
        )
        // Screen-delta math is camera-independent: a finger held still on
        // screen produces a zero delta even if the device drifts a little.
        let firstAxisDelta = axisDeltaInMetres(screenDelta: firstScreenDelta, context: context)
        let secondAxisDelta = axisDeltaInMetres(screenDelta: secondScreenDelta, context: context)

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
        // root by half the imbalance. Each face then moves by exactly its
        // finger's outward delta, including when one finger pushes inward and
        // the other outward. Y is anchored at the floor and never shifts.
        if context.axis != .y {
            let centerShift = (actualPositive - actualNegative) * 0.5
            newPosition += centerShift * context.axisWorld
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

    /// Snapshot of the cuboid frame projected into screen space at gesture
    /// start. Used to map world-axis selection to screen-pixel directions and
    /// to convert finger screen movement into world-axis metres.
    struct AxisProjection {
        let center: CGPoint
        let xVector: CGPoint
        let yVector: CGPoint
        let zVector: CGPoint

        func axisVector(for axis: ARCuboidEntity.Axis) -> CGPoint {
            switch axis {
            case .x: return xVector
            case .y: return yVector
            case .z: return zVector
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

    func projectAxes(
        cuboidCenter: SIMD3<Float>,
        axes: LocalAxes,
        environment env: Environment
    ) -> AxisProjection? {
        guard let center = env.projectToScreen(cuboidCenter),
              let xEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.x),
              let yEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.y),
              let zEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axes.z) else { return nil }
        return AxisProjection(
            center: center,
            xVector: CGPoint(x: xEnd.x - center.x, y: xEnd.y - center.y),
            yVector: CGPoint(x: yEnd.x - center.x, y: yEnd.y - center.y),
            zVector: CGPoint(x: zEnd.x - center.x, y: zEnd.y - center.y)
        )
    }

    func pickActiveAxis(
        projection: AxisProjection,
        firstScreen: CGPoint,
        secondScreen: CGPoint
    ) -> (axis: ARCuboidEntity.Axis, ambiguity: Float)? {
        let fingerDir = CGPoint(x: secondScreen.x - firstScreen.x, y: secondScreen.y - firstScreen.y)
        let candidates: [(ARCuboidEntity.Axis, CGPoint)] = [
            (.x, projection.xVector),
            (.y, projection.yVector),
            (.z, projection.zVector)
        ]
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

    func signedOffset(_ point: CGPoint, from origin: CGPoint, along axisScreenUnit: CGPoint) -> CGFloat {
        (point.x - origin.x) * axisScreenUnit.x + (point.y - origin.y) * axisScreenUnit.y
    }

    private func axisDeltaInMetres(screenDelta: CGPoint, context: ResizeContext) -> Float {
        let projected = screenDelta.x * context.axisScreenUnit.x + screenDelta.y * context.axisScreenUnit.y
        return Float(projected / context.pixelsPerMeter)
    }

    func signedOutwardDelta(face: ARCuboidEntity.Face, axisDelta: Float) -> Float {
        if face == .negativeY { return 0 }
        return face.isPositiveSide ? axisDelta : -axisDelta
    }
}
