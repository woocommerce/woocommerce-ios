import CoreGraphics
import Foundation
import simd

struct ResizeEnvironment {
    var projectToScreen: (SIMD3<Float>) -> CGPoint?
    var isUpperHalfHit: (CGPoint) -> Bool
}

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

    typealias Environment = ResizeEnvironment

    enum Constants {
        static let minSizeMeters: Float = 0.02
        static let jitterThresholdPoints: CGFloat = 1.5
        static let axisProbeDistance: Float = 0.1
        static let minScreenDirectionLength: CGFloat = 1
        static let yAxisAmbiguityThreshold: Float = 0.7
    }

    private struct FingerLatch {
        let face: ARCuboidEntity.Face
        let initialScreen: CGPoint
    }

    private struct ResizeContext {
        let axis: ARCuboidEntity.Axis
        let axisWorld: SIMD3<Float>
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
    private(set) var highlightedFaces: ARCuboidEntity.FaceSet = .empty

    /// May fail silently (no axis pick, missed Y hit-test, projection failure);
    /// the caller can retry on the next gesture frame.
    func begin(input: BeginInput, environment env: Environment) {
        guard let ctx = configureResize(input: input, environment: env) else { return }
        context = ctx
        highlightedFaces = ARCuboidEntity.FaceSet(ctx.firstFinger.face, ctx.secondFinger.face)
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

        let actualTotal = newAxisScale - oldAxisScale
        let scaleFactor: Float = totalDelta == 0 ? 1 : actualTotal / totalDelta
        let actualPositive = outwardPositive * scaleFactor
        let actualNegative = outwardNegative * scaleFactor

        var newScale = context.initialScale
        newScale[axisIndex] = newAxisScale

        var newPosition = context.initialPosition
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
        highlightedFaces = .empty
    }
}

// MARK: - Configuration (one-shot at gesture begin)

private extension CuboidResizeInteraction {
    private func configureResize(input: BeginInput, environment env: Environment) -> ResizeContext? {
        let localAxes = localAxesFromYaw(input.cuboidYaw)
        let cuboidCenter = input.cuboidPosition + 0.5 * input.cuboidScale.y * localAxes[1]

        guard let screenCenter = env.projectToScreen(cuboidCenter) else { return nil }

        let screenVectors = localAxes.compactMap { axis -> CGPoint? in
            guard let end = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axis) else { return nil }
            return CGPoint(x: end.x - screenCenter.x, y: end.y - screenCenter.y)
        }
        guard screenVectors.count == 3 else { return nil }

        guard let axis = pickAxis(fingerDir: fingerDirection(input.fingers), screenVectors: screenVectors, input: input, env: env) else {
            return nil
        }

        let axisWorld = localAxes[axis.simdIndex]
        let axisScreenVec = screenVectors[axis.simdIndex]
        let length = hypot(axisScreenVec.x, axisScreenVec.y)
        guard length > Constants.minScreenDirectionLength else { return nil }

        let axisScreenUnit = CGPoint(x: axisScreenVec.x / length, y: axisScreenVec.y / length)
        let pixelsPerMeter = length / CGFloat(Constants.axisProbeDistance)

        let firstIsPositive = fingerOffset(input.fingers.first, from: screenCenter, along: axisScreenUnit)
            >= fingerOffset(input.fingers.second, from: screenCenter, along: axisScreenUnit)

        return ResizeContext(
            axis: axis,
            axisWorld: axisWorld,
            axisScreenUnit: axisScreenUnit,
            pixelsPerMeter: pixelsPerMeter,
            initialScale: input.cuboidScale,
            initialPosition: input.cuboidPosition,
            firstFinger: FingerLatch(face: .init(axis: axis, isPositiveSide: firstIsPositive), initialScreen: input.fingers.first),
            secondFinger: FingerLatch(face: .init(axis: axis, isPositiveSide: !firstIsPositive), initialScreen: input.fingers.second)
        )
    }

    func pickAxis(
        fingerDir: CGPoint,
        screenVectors: [CGPoint],
        input: BeginInput,
        env: Environment
    ) -> ARCuboidEntity.Axis? {
        let axes: [ARCuboidEntity.Axis] = [.x, .y, .z]
        var bestAxis: ARCuboidEntity.Axis?
        var bestScore: CGFloat = 0
        var secondBestScore: CGFloat = 0
        for (i, dir) in screenVectors.enumerated() {
            let length = max(hypot(dir.x, dir.y), Constants.minScreenDirectionLength)
            let score = abs(fingerDir.x * dir.x + fingerDir.y * dir.y) / length
            if score > bestScore {
                secondBestScore = bestScore
                bestScore = score
                bestAxis = axes[i]
            } else if score > secondBestScore {
                secondBestScore = score
            }
        }
        guard let bestAxis else { return nil }

        if bestAxis == .y {
            let ambiguity: Float = bestScore > 0 ? Float(secondBestScore / bestScore) : 0
            if ambiguity > Constants.yAxisAmbiguityThreshold {
                guard env.isUpperHalfHit(input.fingers.first) || env.isUpperHalfHit(input.fingers.second) else { return nil }
            }
        }

        return bestAxis
    }
}

// MARK: - Per-frame helpers

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

// MARK: - Geometry helpers

private extension CuboidResizeInteraction {
    func localAxesFromYaw(_ yaw: Float) -> [SIMD3<Float>] {
        [
            SIMD3(cos(yaw), 0, -sin(yaw)),
            SIMD3(0, 1, 0),
            SIMD3(sin(yaw), 0, cos(yaw))
        ]
    }

    func fingerDirection(_ fingers: (first: CGPoint, second: CGPoint)) -> CGPoint {
        CGPoint(x: fingers.second.x - fingers.first.x, y: fingers.second.y - fingers.first.y)
    }

    func fingerOffset(_ finger: CGPoint, from center: CGPoint, along unit: CGPoint) -> CGFloat {
        (finger.x - center.x) * unit.x + (finger.y - center.y) * unit.y
    }
}
