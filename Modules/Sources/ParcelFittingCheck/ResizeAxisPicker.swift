import CoreGraphics
import Foundation
import simd

struct ResizeEnvironment {
    var projectToScreen: (SIMD3<Float>) -> CGPoint?
    var isUpperHalfHit: (CGPoint) -> Bool
}

protocol AxisPicking {
    func pick(input: CuboidResizeInteraction.BeginInput, environment: ResizeEnvironment) -> ARCuboidEntity.Axis?
}

/// Decides which cuboid axis a two-finger pinch controls by projecting the
/// cuboid's local axes into screen space and picking the best alignment with
/// the finger pair direction.
struct ResizeAxisPicker: AxisPicking {
    private enum Constants {
        static let yAxisAmbiguityThreshold: Float = 0.7
        static let axisProbeDistance: Float = 0.1
        static let minScreenDirectionLength: CGFloat = 1
    }

    func pick(input: CuboidResizeInteraction.BeginInput, environment env: ResizeEnvironment) -> ARCuboidEntity.Axis? {
        let axisX = SIMD3<Float>(cos(input.cuboidYaw), 0, -sin(input.cuboidYaw))
        let axisY = SIMD3<Float>(0, 1, 0)
        let axisZ = SIMD3<Float>(sin(input.cuboidYaw), 0, cos(input.cuboidYaw))
        let cuboidCenter = input.cuboidPosition + 0.5 * input.cuboidScale.y * axisY

        guard let screenCenter = env.projectToScreen(cuboidCenter),
              let xEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisX),
              let yEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisY),
              let zEnd = env.projectToScreen(cuboidCenter + Constants.axisProbeDistance * axisZ) else { return nil }

        let screenVectors: [(ARCuboidEntity.Axis, CGPoint)] = [
            (.x, CGPoint(x: xEnd.x - screenCenter.x, y: xEnd.y - screenCenter.y)),
            (.y, CGPoint(x: yEnd.x - screenCenter.x, y: yEnd.y - screenCenter.y)),
            (.z, CGPoint(x: zEnd.x - screenCenter.x, y: zEnd.y - screenCenter.y))
        ]

        let fingerDir = CGPoint(x: input.fingers.second.x - input.fingers.first.x,
                                y: input.fingers.second.y - input.fingers.first.y)
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
            guard env.isUpperHalfHit(input.fingers.first) || env.isUpperHalfHit(input.fingers.second) else { return nil }
        }

        return bestAxis
    }
}
