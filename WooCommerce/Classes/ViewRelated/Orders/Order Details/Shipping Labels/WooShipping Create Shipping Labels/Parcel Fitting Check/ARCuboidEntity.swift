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

    // MARK: - Internal

    private struct EdgeSpec {
        let center: SIMD3<Float>
        let size: SIMD3<Float>
    }

    private static func unitBoxEdges() -> [EdgeSpec] {
        let h: Float = 0.5
        let t: Float = 0.006
        let bottomT: Float = 0.012
        var edges: [EdgeSpec] = []

        for y in [Float(0), 1] {
            let thickness = y == 0 ? bottomT : t
            for z in [-h, h] {
                edges.append(EdgeSpec(
                    center: SIMD3(0, y, z),
                    size: SIMD3(1, thickness, thickness)
                ))
            }
        }
        for x in [-h, h] {
            for z in [-h, h] {
                edges.append(EdgeSpec(
                    center: SIMD3(x, 0.5, z),
                    size: SIMD3(t, 1, t)
                ))
            }
        }
        for x in [-h, h] {
            for y in [Float(0), 1] {
                let thickness = y == 0 ? bottomT : t
                edges.append(EdgeSpec(
                    center: SIMD3(x, y, 0),
                    size: SIMD3(thickness, thickness, 1)
                ))
            }
        }
        return edges
    }
}
