import CoreGraphics
import Foundation
import simd

/// Pure state machine for the two-finger resize interaction.
final class CuboidResizeInteraction {
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

    typealias Environment = ResizeAxisPicker.Environment

    enum Constants {
        /// Minimum allowed cuboid size on any axis, in metres.
        static let minSizeMeters: Float = 0.02

        /// Per-frame screen-space dead zone, in points. Below this, finger
        /// movement is treated as touch-sensor jitter and the resize update
        /// is skipped.
        static let jitterThresholdPoints: CGFloat = 1.5

        /// Numerical-stability epsilon for divide-by-zero guards.
        static let nearZeroEpsilon: Float = 1e-6
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
        guard let pick = ResizeAxisPicker.pick(
            cuboidPosition: input.cuboidPosition,
            cuboidScale: input.cuboidScale,
            cuboidYaw: input.cuboidYaw,
            fingers: input.fingers,
            environment: env
        ) else {
            return
        }

        context = ResizeContext(
            axis: pick.axis,
            axisWorld: pick.axisWorld,
            axisScreenUnit: pick.axisScreenUnit,
            pixelsPerMeter: pick.pixelsPerMeter,
            initialScale: input.cuboidScale,
            initialPosition: input.cuboidPosition,
            firstFinger: FingerLatch(face: pick.firstFingerFace, initialScreen: input.fingers.first),
            secondFinger: FingerLatch(face: pick.secondFingerFace, initialScreen: input.fingers.second)
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

private extension CuboidResizeInteraction {
    private func axisDeltaInMetres(screenDelta: CGPoint, context: ResizeContext) -> Float {
        let projected = screenDelta.x * context.axisScreenUnit.x + screenDelta.y * context.axisScreenUnit.y
        return Float(projected / context.pixelsPerMeter)
    }

    func signedOutwardDelta(face: ARCuboidEntity.Face, axisDelta: Float) -> Float {
        if face == .negativeY { return 0 }
        return face.isPositiveSide ? axisDelta : -axisDelta
    }
}
