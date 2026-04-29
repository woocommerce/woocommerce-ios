import RealityKit

/// Builds a wireframe cuboid entity — 12 glowing edges, no fill.
///
/// The returned `ModelEntity` uses a unit-cube local space (bottom at y=0,
/// top at y=1, x/z in [-0.5, 0.5]). Callers set `transform.scale` to the
/// desired dimensions in metres.
enum ARCuboidEntity {
    static func build(color: UIColor = .systemBlue) -> ModelEntity {
        let root = ModelEntity()

        let material = UnlitMaterial(color: color)
        for edge in unitBoxEdges() {
            let bar = ModelEntity(
                mesh: .generateBox(size: edge.size),
                materials: [material]
            )
            bar.position = edge.center
            root.addChild(bar)
        }

        return root
    }
}

// MARK: - Edge geometry

private extension ARCuboidEntity {
    enum UnitCube {
        /// Half the unit cube's extent along any axis. The cube spans
        /// [-0.5, 0.5] in X and Z, and [0, 1] in Y (sits on the surface).
        static let halfExtent: Float = 0.5

        /// Y coordinate of the bottom face (rests on the detected surface).
        static let bottomY: Float = 0

        /// Y coordinate of the top face.
        static let topY: Float = 1

        /// Y coordinate of the vertical centre (used for vertical edges).
        static let midY: Float = 0.5
    }

    enum EdgeThickness {
        /// Default edge thickness in unit space.
        static let regular: Float = 0.006

        /// Bottom-face edges are thicker so the contact line with the
        /// floor reads clearly.
        static let bottom: Float = 0.012
    }

    struct EdgeSpec {
        let center: SIMD3<Float>
        let size: SIMD3<Float>
    }

    static func unitBoxEdges() -> [EdgeSpec] {
        let half = UnitCube.halfExtent
        let minEdge: [Float] = [-half, half]
        var edges: [EdgeSpec] = []

        // 4 edges along X (2 on the bottom face, 2 on the top).
        for faceY in [UnitCube.bottomY, UnitCube.topY] {
            let thickness = faceY == UnitCube.bottomY
                ? EdgeThickness.bottom
                : EdgeThickness.regular
            for depthZ in minEdge {
                edges.append(EdgeSpec(
                    center: SIMD3(0, faceY, depthZ),
                    size: SIMD3(1, thickness, thickness)
                ))
            }
        }

        // 4 vertical edges along Y.
        for sideX in minEdge {
            for depthZ in minEdge {
                edges.append(EdgeSpec(
                    center: SIMD3(sideX, UnitCube.midY, depthZ),
                    size: SIMD3(EdgeThickness.regular, 1, EdgeThickness.regular)
                ))
            }
        }

        // 4 edges along Z (2 on the bottom face, 2 on the top).
        for sideX in minEdge {
            for faceY in [UnitCube.bottomY, UnitCube.topY] {
                let thickness = faceY == UnitCube.bottomY
                    ? EdgeThickness.bottom
                    : EdgeThickness.regular
                edges.append(EdgeSpec(
                    center: SIMD3(sideX, faceY, 0),
                    size: SIMD3(thickness, thickness, 1)
                ))
            }
        }

        return edges
    }
}
