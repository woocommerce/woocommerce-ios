import CoreGraphics
import Foundation
import simd

/// Decides which cuboid axis a two-finger pinch controls and computes the
/// screen-space calibration needed to translate finger motion into world-axis
/// metres.
enum ResizeAxisPicker {
    struct Environment {
        var projectToScreen: (SIMD3<Float>) -> CGPoint?
        var isUpperHalfHit: (CGPoint) -> Bool
    }

    struct Result {
        let axis: ARCuboidEntity.Axis
        let axisWorld: SIMD3<Float>
        /// Unit vector along `axis` projected into screen space at gesture
        /// start. Multiplied by `pixelsPerMeter`, it converts screen-pixel
        /// movement along this direction into world-axis metres.
        let axisScreenUnit: CGPoint
        let pixelsPerMeter: CGFloat
        let firstFingerFace: ARCuboidEntity.Face
        let secondFingerFace: ARCuboidEntity.Face
    }

    enum Constants {
        /// When Y wins the screen-space alignment race, an X or Z axis whose
        /// screen direction is close to Y's is a plausible alternative; below
        /// this ratio (second-best / best) Y is the clear winner and the
        /// hit-test is skipped. 0.7 ≈ ~45° of screen-direction separation.
        static let yAxisAmbiguityThreshold: Float = 0.7

        /// Distance, in metres, of the axis probe from the cuboid centre when
        /// projecting world-space axes into screen space for the pinch
        /// direction match.
        static let axisProbeDistance: Float = 0.1

        /// Floor for screen-direction lengths to avoid divide-by-zero when
        /// scoring the axis pick.
        static let minScreenDirectionLength: CGFloat = 1
    }

    /// May fail (no axis pick, missed Y hit-test, projection failure); the
    /// caller can retry on the next gesture frame.
    static func pick(
        cuboidPosition: SIMD3<Float>,
        cuboidScale: SIMD3<Float>,
        cuboidYaw: Float,
        fingers: (first: CGPoint, second: CGPoint),
        environment env: Environment
    ) -> Result? {
        let axes = localAxes(yaw: cuboidYaw)
        // Cuboid local Y is 0…1 with the root at the floor, so the geometric
        // centre sits half-a-height up.
        let cuboidCenter = cuboidPosition + 0.5 * cuboidScale.y * axes.y

        guard let projection = projectAxes(cuboidCenter: cuboidCenter, axes: axes, environment: env) else {
            return nil
        }
        guard let pick = bestAxis(
            projection: projection,
            firstScreen: fingers.first,
            secondScreen: fingers.second
        ) else {
            return nil
        }

        // For Y, a vertical screen-space pinch is the natural cue. We accept
        // it without a hit-test when Y dominates; only when X or Z projects
        // close to Y's screen direction do we fall back to requiring at least
        // one finger on the upper half of the cuboid.
        if pick.axis == .y && pick.ambiguity > Constants.yAxisAmbiguityThreshold {
            let firstUpper = env.isUpperHalfHit(fingers.first)
            let secondUpper = env.isUpperHalfHit(fingers.second)
            guard firstUpper || secondUpper else { return nil }
        }

        let axisScreenVec = projection.axisVector(for: pick.axis)
        let length = hypot(axisScreenVec.x, axisScreenVec.y)
        guard length > Constants.minScreenDirectionLength else { return nil }
        let axisScreenUnit = CGPoint(x: axisScreenVec.x / length, y: axisScreenVec.y / length)
        let pixelsPerMeter = length / CGFloat(Constants.axisProbeDistance)

        // Score each finger's signed screen offset along the axis to decide
        // which drives the +face vs the −face (the larger projection drives
        // +face), even when both fingers are on the same side of the cuboid.
        let firstAxisOffset = signedOffset(fingers.first, from: projection.center, along: axisScreenUnit)
        let secondAxisOffset = signedOffset(fingers.second, from: projection.center, along: axisScreenUnit)
        let firstIsPositive = firstAxisOffset >= secondAxisOffset

        return Result(
            axis: pick.axis,
            axisWorld: axes[pick.axis],
            axisScreenUnit: axisScreenUnit,
            pixelsPerMeter: pixelsPerMeter,
            firstFingerFace: ARCuboidEntity.Face(axis: pick.axis, isPositiveSide: firstIsPositive),
            secondFingerFace: ARCuboidEntity.Face(axis: pick.axis, isPositiveSide: !firstIsPositive)
        )
    }
}

private extension ResizeAxisPicker {
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

    static func localAxes(yaw: Float) -> LocalAxes {
        LocalAxes(
            x: SIMD3(cos(yaw), 0, -sin(yaw)),
            y: SIMD3(0, 1, 0),
            z: SIMD3(sin(yaw), 0, cos(yaw))
        )
    }

    static func projectAxes(
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

    static func bestAxis(
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

    static func signedOffset(_ point: CGPoint, from origin: CGPoint, along axisScreenUnit: CGPoint) -> CGFloat {
        (point.x - origin.x) * axisScreenUnit.x + (point.y - origin.y) * axisScreenUnit.y
    }
}
