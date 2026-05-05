import CoreGraphics
import Foundation
import simd

/// Decides which cuboid axis a two-finger pinch controls by projecting the
/// cuboid's local axes into screen space and picking the best alignment with
/// the finger pair direction.
enum ResizeAxisPicker {
    struct Environment {
        var projectToScreen: (SIMD3<Float>) -> CGPoint?
        var isUpperHalfHit: (CGPoint) -> Bool
    }

    enum Constants {
        static let yAxisAmbiguityThreshold: Float = 0.7
        static let axisProbeDistance: Float = 0.1
        static let minScreenDirectionLength: CGFloat = 1
    }

    /// Returns the axis the pinch should control, or nil if no axis can be
    /// determined (projection failure, ambiguous Y without hit-test, etc.).
    static func pick(
        cuboidPosition: SIMD3<Float>,
        cuboidScale: SIMD3<Float>,
        cuboidYaw: Float,
        fingers: (first: CGPoint, second: CGPoint),
        environment env: Environment
    ) -> ARCuboidEntity.Axis? {
        let axisX = SIMD3<Float>(cos(cuboidYaw), 0, -sin(cuboidYaw))
        let axisY = SIMD3<Float>(0, 1, 0)
        let axisZ = SIMD3<Float>(sin(cuboidYaw), 0, cos(cuboidYaw))
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

        if bestAxis == .y && ambiguity > Constants.yAxisAmbiguityThreshold {
            guard env.isUpperHalfHit(fingers.first) || env.isUpperHalfHit(fingers.second) else { return nil }
        }

        return bestAxis
    }
}
