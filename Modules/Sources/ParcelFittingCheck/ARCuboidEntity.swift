import UIKit
import RealityKit

/// Unit-cube wireframe (12 edges, no fill). Callers set `transform.scale`
/// to the desired dimensions in metres. Bottom at y=0, top at y=1.
struct ARCuboidEntity {
    private init() {}

    static func build(color: UIColor = .systemBlue) -> ModelEntity {
        let root = ModelEntity()
        let material = UnlitMaterial(color: color)
        for edge in unitBoxEdges() {
            let bar = ModelEntity(mesh: .generateBox(size: edge.size), materials: [material])
            bar.position = edge.center
            root.addChild(bar)
        }
        return root
    }
}

private extension ARCuboidEntity {
    enum UnitCube {
        static let halfExtent: Float = 0.5
        static let bottomY: Float = 0
        static let topY: Float = 1
        static let midY: Float = 0.5
    }

    enum EdgeThickness {
        static let regular: Float = 0.006
        /// Bottom edges are thicker so the floor contact line reads clearly.
        static let bottom: Float = 0.012
    }

    struct EdgeSpec {
        let center: SIMD3<Float>
        let size: SIMD3<Float>
    }

    static func unitBoxEdges() -> [EdgeSpec] {
        let half = UnitCube.halfExtent
        let extents: [Float] = [-half, half]
        var edges: [EdgeSpec] = []

        for faceY in [UnitCube.bottomY, UnitCube.topY] {
            let t = faceY == UnitCube.bottomY ? EdgeThickness.bottom : EdgeThickness.regular
            for depthZ in extents {
                edges.append(EdgeSpec(center: SIMD3(0, faceY, depthZ), size: SIMD3(1, t, t)))
            }
        }
        for sideX in extents {
            for depthZ in extents {
                edges.append(EdgeSpec(
                    center: SIMD3(sideX, UnitCube.midY, depthZ),
                    size: SIMD3(EdgeThickness.regular, 1, EdgeThickness.regular)
                ))
            }
        }
        for sideX in extents {
            for faceY in [UnitCube.bottomY, UnitCube.topY] {
                let t = faceY == UnitCube.bottomY ? EdgeThickness.bottom : EdgeThickness.regular
                edges.append(EdgeSpec(center: SIMD3(sideX, faceY, 0), size: SIMD3(t, t, 1)))
            }
        }
        return edges
    }
}
