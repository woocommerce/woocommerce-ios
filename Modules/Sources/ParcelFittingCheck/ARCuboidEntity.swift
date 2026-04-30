import UIKit
import RealityKit

/// Unit-cube wireframe (12 edges, no fill). Callers set `root.transform.scale`
/// to the desired dimensions in metres. Bottom at y=0, top at y=1.
struct ARCuboidEntity {
    enum Axis { case x, y, z }

    enum Face: Hashable {
        case positiveX, negativeX, positiveY, negativeY, positiveZ, negativeZ

        var axis: Axis {
            switch self {
            case .positiveX, .negativeX: return .x
            case .positiveY, .negativeY: return .y
            case .positiveZ, .negativeZ: return .z
            }
        }

        var isPositiveSide: Bool {
            switch self {
            case .positiveX, .positiveY, .positiveZ: return true
            case .negativeX, .negativeY, .negativeZ: return false
            }
        }

        static func positiveSide(of axis: Axis) -> Face {
            switch axis {
            case .x: return .positiveX
            case .y: return .positiveY
            case .z: return .positiveZ
            }
        }

        static func negativeSide(of axis: Axis) -> Face {
            switch axis {
            case .x: return .negativeX
            case .y: return .negativeY
            case .z: return .negativeZ
            }
        }
    }

    let root: ModelEntity
    let edges: [ModelEntity]
    private let baseColor: UIColor
    private let highlightColor: UIColor

    private init(root: ModelEntity, edges: [ModelEntity], baseColor: UIColor, highlightColor: UIColor) {
        self.root = root
        self.edges = edges
        self.baseColor = baseColor
        self.highlightColor = highlightColor
    }

    static func build(color: UIColor = .systemBlue, highlightColor: UIColor = .systemYellow) -> ARCuboidEntity {
        let root = ModelEntity()
        var bars: [ModelEntity] = []
        bars.reserveCapacity(12)
        for edge in unitBoxEdges() {
            var material = UnlitMaterial()
            material.color = .init(tint: color)
            let bar = ModelEntity(mesh: .generateBox(size: edge.size), materials: [material])
            bar.position = edge.center
            root.addChild(bar)
            bars.append(bar)
        }
        return ARCuboidEntity(root: root, edges: bars, baseColor: color, highlightColor: highlightColor)
    }

    /// Per-frame material update: fades each edge by camera distance to disambiguate
    /// front/back of the wireframe, and recolors edges of `highlightedFaces` so
    /// the user can see which faces a gesture is currently controlling.
    func updateMaterials(cameraPosition: SIMD3<Float>, highlightedFaces: Set<Face> = []) {
        guard !edges.isEmpty else { return }

        let highlightedIndices: Set<Int> = highlightedFaces.reduce(into: []) { acc, face in
            acc.formUnion(Self.faceEdgeIndices[face] ?? [])
        }

        var distances: [Float] = []
        distances.reserveCapacity(edges.count)
        var minDistance = Float.greatestFiniteMagnitude
        var maxDistance: Float = 0
        for edge in edges {
            let world = edge.position(relativeTo: nil)
            let distance = simd_distance(world, cameraPosition)
            distances.append(distance)
            if distance < minDistance { minDistance = distance }
            if distance > maxDistance { maxDistance = distance }
        }

        let range = max(maxDistance - minDistance, AlphaFade.minRange)
        for (index, edge) in edges.enumerated() {
            let t = (distances[index] - minDistance) / range
            let alpha = AlphaFade.near + (AlphaFade.far - AlphaFade.near) * t
            let color = highlightedIndices.contains(index) ? highlightColor : baseColor
            guard var material = edge.model?.materials.first as? UnlitMaterial else { continue }
            material.color = .init(tint: color)
            material.blending = .transparent(opacity: .init(floatLiteral: alpha))
            edge.model?.materials[0] = material
        }
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

    enum AlphaFade {
        static let near: Float = 1.0
        static let far: Float = 0.5
        static let minRange: Float = 0.0001
    }

    struct EdgeSpec {
        let center: SIMD3<Float>
        let size: SIMD3<Float>
    }

    /// Edge indices that bound each face. The order matches `unitBoxEdges()`:
    /// 0–3 are X-aligned (top/bottom along Z), 4–7 are Y-aligned (vertical),
    /// 8–11 are Z-aligned (top/bottom along X).
    static let faceEdgeIndices: [Face: [Int]] = [
        .positiveX: [6, 7, 10, 11],
        .negativeX: [4, 5, 8, 9],
        .positiveY: [2, 3, 9, 11],
        .negativeY: [0, 1, 8, 10],
        .positiveZ: [1, 3, 5, 7],
        .negativeZ: [0, 2, 4, 6]
    ]

    static func unitBoxEdges() -> [EdgeSpec] {
        let half = UnitCube.halfExtent
        let extents: [Float] = [-half, half]
        var edges: [EdgeSpec] = []

        for faceY in [UnitCube.bottomY, UnitCube.topY] {
            let thickness = faceY == UnitCube.bottomY ? EdgeThickness.bottom : EdgeThickness.regular
            for depthZ in extents {
                edges.append(EdgeSpec(center: SIMD3(0, faceY, depthZ), size: SIMD3(1, thickness, thickness)))
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
                let thickness = faceY == UnitCube.bottomY ? EdgeThickness.bottom : EdgeThickness.regular
                edges.append(EdgeSpec(center: SIMD3(sideX, faceY, 0), size: SIMD3(thickness, thickness, 1)))
            }
        }
        return edges
    }
}
