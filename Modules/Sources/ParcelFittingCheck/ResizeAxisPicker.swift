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
        let axisX = SIMD3<Float>(cos(cuboidYaw), 0, -sin(cuboidYaw))
        let axisY = SIMD3<Float>(0, 1, 0)
        let axisZ = SIMD3<Float>(sin(cuboidYaw), 0, cos(cuboidYaw))
        // Cuboid local Y is 0…1 with the root at the floor, so the geometric
        // centre sits half-a-height up.
        let cuboidCenter = cuboidPosition + 0.5 * cuboidScale.y * axisY

        guard let screenCenter = env.projectToScreen(cuboidCenter),
              let xEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisX),
              let yEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisY),
              let zEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisZ) else { return nil }

        let screenVectors: [(ARCuboidEntity.Axis, CGPoint)] = [
            (.x, CGPoint(x: xEnd.x - screenCenter.x, y: xEnd.y - screenCenter.y)),
            (.y, CGPoint(x: yEnd.x - screenCenter.x, y: yEnd.y - screenCenter.y)),
            (.z, CGPoint(x: zEnd.x - screenCenter.x, y: zEnd.y - screenCenter.y))
        ]

        // Pick whichever axis's screen direction best aligns with the finger pair.
        let fingerDir = CGPoint(x: fingers.second.x - fingers.first.x, y: fingers.second.y - fingers.first.y)
        var bestAxis: ARCuboidEntity.Axis?
        var bestScore: CGFloat = 0
        var secondBestScore: CGFloat = 0
        for (axis, dir) in screenVectors {
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

        // For Y, a vertical screen-space pinch is the natural cue. We accept
        // it without a hit-test when Y dominates; only when X or Z projects
        // close to Y's screen direction do we fall back to requiring at least
        // one finger on the upper half of the cuboid.
        if bestAxis == .y && ambiguity > Constants.yAxisAmbiguityThreshold {
            guard env.isUpperHalfHit(fingers.first) || env.isUpperHalfHit(fingers.second) else { return nil }
        }

        let axisScreenVec = screenVectors[bestAxis.simdIndex].1
        let length = hypot(axisScreenVec.x, axisScreenVec.y)
        guard length > Constants.minScreenDirectionLength else { return nil }
        let axisScreenUnit = CGPoint(x: axisScreenVec.x / length, y: axisScreenVec.y / length)
        let pixelsPerMeter = length / CGFloat(Constants.axisProbeDistance)

        let axisWorld: SIMD3<Float> = switch bestAxis {
        case .x: axisX
        case .y: axisY
        case .z: axisZ
        }

        // The finger with larger projection along the axis drives the +face.
        let firstOffset = (fingers.first.x - screenCenter.x) * axisScreenUnit.x
            + (fingers.first.y - screenCenter.y) * axisScreenUnit.y
        let secondOffset = (fingers.second.x - screenCenter.x) * axisScreenUnit.x
            + (fingers.second.y - screenCenter.y) * axisScreenUnit.y
        let firstIsPositive = firstOffset >= secondOffset

        return Result(
            axis: bestAxis,
            axisWorld: axisWorld,
            axisScreenUnit: axisScreenUnit,
            pixelsPerMeter: pixelsPerMeter,
            firstFingerFace: ARCuboidEntity.Face(axis: bestAxis, isPositiveSide: firstIsPositive),
            secondFingerFace: ARCuboidEntity.Face(axis: bestAxis, isPositiveSide: !firstIsPositive)
        )
    }
}
