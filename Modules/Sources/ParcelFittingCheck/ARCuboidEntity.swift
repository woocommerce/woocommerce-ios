import UIKit
import RealityKit

/// Unit-cube wireframe (12 edges, no fill). Callers set `root.transform.scale`
/// to the desired dimensions in metres. Bottom at y=0, top at y=1.
///
/// Each edge has two presentations: a solid box and a dashed alternative.
/// `updateMaterials` toggles visibility per frame so edges adjacent to a
/// camera-facing face render as solid and edges that would be hidden by an
/// opaque cuboid render as dashed — the standard CAD hidden-line look.
struct ARCuboidEntity {
    enum Axis {
        case x, y, z

        var simdIndex: Int {
            switch self {
            case .x: return 0
            case .y: return 1
            case .z: return 2
            }
        }
    }

    let root: ModelEntity
    private let edges: [Edge]
    private let baseColor: UIColor
    private let highlightColor: UIColor

    private struct Edge {
        let solid: ModelEntity
        /// Parent of the dash segments. Toggling visibility on the parent
        /// hides every segment in one shot. Children are rebuilt lazily by
        /// `updateMaterials` whenever the cuboid scale changes the target
        /// dash count for this edge.
        let dashedGroup: ModelEntity
        let spec: EdgeSpec
    }

    private init(root: ModelEntity, edges: [Edge], baseColor: UIColor, highlightColor: UIColor) {
        self.root = root
        self.edges = edges
        self.baseColor = baseColor
        self.highlightColor = highlightColor
    }

    static func build(color: UIColor = .systemBlue, highlightColor: UIColor = .systemYellow) -> ARCuboidEntity {
        let root = ModelEntity()
        var edges: [Edge] = []
        edges.reserveCapacity(12)
        for spec in EdgeSpec.unitCubeEdges {
            let solid = makeBox(size: spec.size, color: color)
            solid.position = spec.center
            root.addChild(solid)

            let dashedGroup = ModelEntity()
            dashedGroup.position = spec.center
            // Dashes are populated on the first updateMaterials call so the
            // count tracks the cuboid's actual world-space dimensions.
            root.addChild(dashedGroup)

            edges.append(Edge(
                solid: solid,
                dashedGroup: dashedGroup,
                spec: spec
            ))
        }
        return ARCuboidEntity(root: root, edges: edges, baseColor: color, highlightColor: highlightColor)
    }

    /// Per-frame update: classifies each edge as front (solid) or back
    /// (dashed) based on which faces are camera-facing, and applies the
    /// highlight colour where requested. Highlight changes colour only —
    /// the dashing pattern is the same whether an edge is highlighted or not.
    func updateMaterials(cameraPosition: SIMD3<Float>, highlightedFaces: Set<Face> = []) {
        guard !edges.isEmpty else { return }

        let scale = root.transform.scale
        let cameraFacing = cameraFacingFaces(cameraPosition: cameraPosition)

        for edge in edges {
            // Counter-scale the edge so the parent's per-axis scale stretches
            // the length but leaves world-space thickness constant. Skip the
            // write when the parent scale has not changed — otherwise we would
            // dirty the transform component every frame for an idle parcel.
            let edgeScale = edge.spec.compensatingScale(parentScale: scale)
            if edge.solid.transform.scale != edgeScale {
                edge.solid.transform.scale = edgeScale
                edge.dashedGroup.transform.scale = edgeScale
            }

            let axisScale = scale[edge.spec.lengthAxis.simdIndex]
            let targetCount = dashCount(forWorldLength: axisScale)
            if edge.dashedGroup.children.count != targetCount {
                rebuildDashes(in: edge, count: targetCount)
            }

            let (face1, face2) = edge.spec.adjacentFaces
            let isHighlighted = highlightedFaces.contains(face1) || highlightedFaces.contains(face2)
            let isFront = cameraFacing.contains(face1) || cameraFacing.contains(face2)

            edge.solid.isEnabled = isFront
            edge.dashedGroup.isEnabled = !isFront

            let color = isHighlighted ? highlightColor : baseColor
            if isFront {
                applyColor(color, to: edge.solid)
            } else {
                for child in edge.dashedGroup.children {
                    if let model = child as? ModelEntity {
                        applyColor(color, to: model)
                    }
                }
            }
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

    enum DashPattern {
        /// World-space length (metres) of one dash + one gap. A 2 cm unit
        /// gives ~1 cm dashes spaced ~1 cm apart at the default dash fraction.
        static let targetWorldUnitLength: Float = 0.02
        /// Fraction of each cell occupied by the dash; the rest is the gap.
        static let dashFraction: Float = 0.5
        /// Minimum number of dashes per edge so very short edges still read
        /// as dashed rather than collapsing to a single segment.
        static let minSegmentCount: Int = 3
    }

    struct EdgeSpec {
        let center: SIMD3<Float>
        let size: SIMD3<Float>

        var lengthAxis: Axis {
            if size.x >= size.y && size.x >= size.z { return .x }
            if size.y >= size.x && size.y >= size.z { return .y }
            return .z
        }

        /// Per-axis scale that, applied to a child of a parent scaled by
        /// `parentScale`, leaves the edge stretched along its length axis but
        /// keeps its cross-section a fixed world-space thickness.
        func compensatingScale(parentScale: SIMD3<Float>) -> SIMD3<Float> {
            let sx = max(parentScale.x, 1e-6)
            let sy = max(parentScale.y, 1e-6)
            let sz = max(parentScale.z, 1e-6)
            switch lengthAxis {
            case .x: return SIMD3(1, 1 / sy, 1 / sz)
            case .y: return SIMD3(1 / sx, 1, 1 / sz)
            case .z: return SIMD3(1 / sx, 1 / sy, 1)
            }
        }

        func dashSegmentSize(count: Int) -> SIMD3<Float> {
            let dashLength = Float(1) / Float(count) * DashPattern.dashFraction
            switch lengthAxis {
            case .x: return SIMD3(dashLength, size.y, size.z)
            case .y: return SIMD3(size.x, dashLength, size.z)
            case .z: return SIMD3(size.x, size.y, dashLength)
            }
        }

        func dashSegmentOffset(segmentIndex: Int, count: Int) -> SIMD3<Float> {
            let cellCenter = -0.5 + (Float(segmentIndex) + 0.5) / Float(count)
            switch lengthAxis {
            case .x: return SIMD3(cellCenter, 0, 0)
            case .y: return SIMD3(0, cellCenter, 0)
            case .z: return SIMD3(0, 0, cellCenter)
            }
        }

        /// The two faces of the unit cube that share this edge.
        var adjacentFaces: (Face, Face) {
            switch lengthAxis {
            case .x:
                // X-aligned edges run along ±X; the two perpendicular signs
                // (Y, Z) pick the adjacent faces.
                let yFace: Face = center.y >= UnitCube.midY ? .positiveY : .negativeY
                let zFace: Face = center.z >= 0 ? .positiveZ : .negativeZ
                return (yFace, zFace)
            case .y:
                let xFace: Face = center.x >= 0 ? .positiveX : .negativeX
                let zFace: Face = center.z >= 0 ? .positiveZ : .negativeZ
                return (xFace, zFace)
            case .z:
                let xFace: Face = center.x >= 0 ? .positiveX : .negativeX
                let yFace: Face = center.y >= UnitCube.midY ? .positiveY : .negativeY
                return (xFace, yFace)
            }
        }

        /// The 12 edges of a unit cube (X spanning −0.5…+0.5, Y spanning 0…1,
        /// Z spanning −0.5…+0.5), each with the regular wireframe thickness.
        static let unitCubeEdges: [EdgeSpec] = {
            let half = UnitCube.halfExtent
            let extents: [Float] = [-half, half]
            let thickness: Float = 0.005
            var edges: [EdgeSpec] = []

            for faceY in [UnitCube.bottomY, UnitCube.topY] {
                for depthZ in extents {
                    edges.append(EdgeSpec(center: SIMD3(0, faceY, depthZ), size: SIMD3(1, thickness, thickness)))
                }
            }
            for sideX in extents {
                for depthZ in extents {
                    edges.append(EdgeSpec(
                        center: SIMD3(sideX, UnitCube.midY, depthZ),
                        size: SIMD3(thickness, 1, thickness)
                    ))
                }
            }
            for sideX in extents {
                for faceY in [UnitCube.bottomY, UnitCube.topY] {
                    edges.append(EdgeSpec(center: SIMD3(sideX, faceY, 0), size: SIMD3(thickness, thickness, 1)))
                }
            }
            return edges
        }()
    }

    static func makeBox(size: SIMD3<Float>, color: UIColor) -> ModelEntity {
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        return ModelEntity(mesh: .generateBox(size: size), materials: [material])
    }

    func dashCount(forWorldLength length: Float) -> Int {
        max(DashPattern.minSegmentCount, Int(round(length / DashPattern.targetWorldUnitLength)))
    }

    private func rebuildDashes(in edge: Edge, count: Int) {
        for child in Array(edge.dashedGroup.children) {
            child.removeFromParent()
        }
        for i in 0..<count {
            let segment = Self.makeBox(
                size: edge.spec.dashSegmentSize(count: count),
                color: baseColor
            )
            segment.position = edge.spec.dashSegmentOffset(segmentIndex: i, count: count)
            edge.dashedGroup.addChild(segment)
        }
    }

    /// Returns the set of faces whose outward normal points toward the
    /// camera. Computed in unit-cube local space (X/Z: ±0.5, Y: 0…1) so
    /// the cuboid's yaw and scale are factored out.
    func cameraFacingFaces(cameraPosition: SIMD3<Float>) -> Set<Face> {
        let scale = root.transform.scale
        let inverseRotation = root.transform.rotation.inverse
        let relative = cameraPosition - root.position
        let rotated = inverseRotation.act(relative)
        let unitCam = SIMD3<Float>(
            rotated.x / max(scale.x, 1e-6),
            rotated.y / max(scale.y, 1e-6),
            rotated.z / max(scale.z, 1e-6)
        )

        var result: Set<Face> = []
        if unitCam.x > UnitCube.halfExtent { result.insert(.positiveX) }
        if unitCam.x < -UnitCube.halfExtent { result.insert(.negativeX) }
        if unitCam.y > UnitCube.topY { result.insert(.positiveY) }
        if unitCam.y < UnitCube.bottomY { result.insert(.negativeY) }
        if unitCam.z > UnitCube.halfExtent { result.insert(.positiveZ) }
        if unitCam.z < -UnitCube.halfExtent { result.insert(.negativeZ) }
        return result
    }

    func applyColor(_ color: UIColor, to entity: ModelEntity) {
        guard var material = entity.model?.materials.first as? UnlitMaterial else { return }
        material.color = .init(tint: color)
        entity.model?.materials[0] = material
    }
}
