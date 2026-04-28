import SwiftUI
import RealityKit
import ARKit

/// Shared AR cuboid component used by both `ARParcelSizingView` (Custom flow,
/// resize enabled) and `ARParcelFitCheckView` (Carrier flow, resize disabled).
///
/// The cuboid looks and behaves identically in both contexts; the difference
/// lives in the parent view (which slider/picker chrome is shown). Dimensions
/// are always supplied externally — the component itself just renders the
/// cuboid at the current size and handles placement, drag (translate on the
/// detected horizontal plane) and 2-finger yaw rotation.
///
/// State machine:
/// - Pre-placement: a small ghost preview marker tracks the centre raycast
///   target. `hasValidTarget` reflects whether the raycast finds a surface,
///   which the parent uses to enable the "+" button.
/// - Post-placement: the cuboid is anchored, gestures are active, the trash
///   button (in the parent) returns to pre-placement state.
struct ARCuboidView: UIViewRepresentable {
    /// Cuboid dimensions in metres: `x = length`, `y = height`, `z = width`.
    let dimensions: SIMD3<Float>
    @Binding var hasValidTarget: Bool
    @Binding var isPlaced: Bool
    /// Increment to place the cuboid at the current reticle target.
    let placeTrigger: Int
    /// Increment to remove the cuboid and return to placement state.
    let resetTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(hasValidTarget: $hasValidTarget,
                    isPlaced: $isPlaced)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        // Stop ARKit's automatic light-probe estimation. Otherwise the
        // PBR fill material re-shades every time the camera moves, causing
        // dark patches to drift across the cuboid as the user pans around.
        config.isLightEstimationEnabled = false
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        // Visual feedback for finding a horizontal plane.
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.activatesAutomatically = true
        coaching.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coaching)
        NSLayoutConstraint.activate([
            coaching.topAnchor.constraint(equalTo: arView.topAnchor),
            coaching.bottomAnchor.constraint(equalTo: arView.bottomAnchor),
            coaching.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coaching.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
        ])

        arView.environment.sceneUnderstanding.options = [.occlusion]

        // Disable RealityKit's automatic grounding shadow. Otherwise the
        // contact shadow under the cuboid is visible through the
        // translucent fill and looks like an interior shadow.
        arView.renderOptions.insert(.disableGroundingShadows)

        // Screen-wide two-finger rotation (like ParcelBroker AR). Starts
        // disabled; enabled once the cuboid is placed.
        let rotation = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        rotation.delegate = context.coordinator
        rotation.isEnabled = false
        arView.addGestureRecognizer(rotation)
        context.coordinator.rotationGesture = rotation

        context.coordinator.arView = arView
        context.coordinator.dimensions = dimensions
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.lastPlaceTrigger != placeTrigger {
            context.coordinator.lastPlaceTrigger = placeTrigger
            context.coordinator.placeAtTarget()
        }
        if context.coordinator.lastResetTrigger != resetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger
            context.coordinator.removeCuboid()
        }
        context.coordinator.updateDimensions(dimensions)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate, UIGestureRecognizerDelegate {
        weak var arView: ARView?

        @Binding var hasValidTarget: Bool
        @Binding var isPlaced: Bool

        var dimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
        var lastPlaceTrigger: Int = 0
        var lastResetTrigger: Int = 0

        // Pre-placement
        private var rootAnchor: AnchorEntity?
        private var ghostMarker: ModelEntity?
        private var currentTarget: SIMD3<Float>?

        // Placed cuboid
        private var cuboidAnchor: AnchorEntity?
        private var cuboidEntity: ModelEntity?
        private var installedGestures: [EntityGestureRecognizer] = []

        // Screen-wide rotation
        var rotationGesture: UIRotationGestureRecognizer?
        private var rotationStartYaw: Float = 0

        init(hasValidTarget: Binding<Bool>, isPlaced: Binding<Bool>) {
            self._hasValidTarget = hasValidTarget
            self._isPlaced = isPlaced
        }

        // MARK: ARSessionDelegate

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            if !isPlaced {
                updateTarget()
            }
        }

        // MARK: Public actions

        func placeAtTarget() {
            guard !isPlaced, let target = currentTarget else { return }
            clearGhost()
            buildCuboid(at: target)
            installCuboidGestures()
            // Defer the @Binding write — `placeAtTarget` is called from
            // `updateUIView` which is itself inside a SwiftUI view-update
            // pass. State writes during a render pass are silently
            // dropped, so the parent never switches to the "placed" UI.
            DispatchQueue.main.async { [weak self] in
                self?.isPlaced = true
            }
        }

        func removeCuboid() {
            uninstallCuboidGestures()
            if let cuboidAnchor, let arView {
                arView.scene.removeAnchor(cuboidAnchor)
            }
            cuboidAnchor = nil
            cuboidEntity = nil
            DispatchQueue.main.async { [weak self] in
                self?.isPlaced = false
            }
        }

        private func installCuboidGestures() {
            guard let arView, let cuboidEntity else { return }
            // Collision shape for RealityKit's translation gesture.
            cuboidEntity.collision = CollisionComponent(
                shapes: [
                    .generateBox(size: SIMD3(1, 1, 1))
                        .offsetBy(translation: SIMD3(0, 0.5, 0))
                ]
            )
            // Translation via entity-targeted gesture (drag on the cuboid).
            // Rotation is handled separately via a screen-wide
            // UIRotationGestureRecognizer so the user can two-finger twist
            // anywhere — not just on the wireframe edges.
            installedGestures = arView.installGestures(
                [.translation],
                for: cuboidEntity
            )
            rotationGesture?.isEnabled = true
        }

        private func uninstallCuboidGestures() {
            guard let arView else { return }
            for gesture in installedGestures {
                arView.removeGestureRecognizer(gesture)
            }
            installedGestures.removeAll()
            rotationGesture?.isEnabled = false
        }

        // MARK: Screen-wide rotation

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let cuboidEntity else { return }

            switch gesture.state {
            case .began:
                let q = cuboidEntity.transform.rotation
                rotationStartYaw = 2 * atan2(q.imag.y, q.real)
            case .changed:
                let yaw = rotationStartYaw - Float(gesture.rotation)
                cuboidEntity.transform.rotation = simd_quatf(
                    angle: yaw,
                    axis: SIMD3(0, 1, 0)
                )
            default:
                break
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func updateDimensions(_ dims: SIMD3<Float>) {
            dimensions = dims
            cuboidEntity?.transform.scale = dims
        }

        // MARK: Per-frame placement target

        private func updateTarget() {
            guard let arView, arView.bounds.width > 0 else { return }
            let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)

            guard let world = raycastWorldPosition(from: center, in: arView) else {
                if hasValidTarget { hasValidTarget = false }
                clearGhost()
                currentTarget = nil
                return
            }

            currentTarget = world
            if !hasValidTarget { hasValidTarget = true }

            ensureRootAnchor()
            updateGhost(at: world)
        }

        private func ensureRootAnchor() {
            guard let arView, rootAnchor == nil else { return }
            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            arView.scene.addAnchor(anchor)
            rootAnchor = anchor
        }

        private func updateGhost(at world: SIMD3<Float>) {
            guard let rootAnchor else { return }
            if let existing = ghostMarker {
                existing.position = world
            } else {
                let marker = ModelEntity(
                    mesh: .generateBox(size: 0.012, cornerRadius: 0.002),
                    materials: [UnlitMaterial(color: UIColor.systemBlue.withAlphaComponent(0.5))]
                )
                marker.position = world
                rootAnchor.addChild(marker)
                ghostMarker = marker
            }
        }

        private func clearGhost() {
            ghostMarker?.removeFromParent()
            ghostMarker = nil
        }

        // MARK: Cuboid construction

        private func buildCuboid(at world: SIMD3<Float>) {
            guard let arView else { return }

            // Root must be a `ModelEntity` so RealityKit's translation
            // gesture can target it. The root itself has no model; only
            // the wireframe edges are children.
            let root = ModelEntity()
            root.position = world
            root.transform.scale = dimensions

            // Wireframe edges only — no translucent fill. ParcelBroker AR
            // uses the same approach: the cuboid is just 12 glowing edges.
            // This sidesteps every occlusion / shading issue we hit with a
            // filled volume.
            let edgeMaterial = UnlitMaterial(color: .systemBlue)
            for edge in unitBoxEdges() {
                let bar = ModelEntity(
                    mesh: .generateBox(size: edge.size),
                    materials: [edgeMaterial]
                )
                bar.position = edge.center
                root.addChild(bar)
            }

            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            anchor.addChild(root)
            arView.scene.addAnchor(anchor)

            cuboidAnchor = anchor
            cuboidEntity = root
        }

        private struct EdgeSpec {
            let center: SIMD3<Float>
            let size: SIMD3<Float>
        }

        /// Edges of a unit cube whose bottom face sits on the surface (y=0)
        /// and top face at y=1, x and z in [-0.5, 0.5].
        private func unitBoxEdges() -> [EdgeSpec] {
            let h: Float = 0.5
            let t: Float = 0.003          // regular edge thickness
            let bottomT: Float = 0.006    // emphasised bottom-face edges so
                                          // the contact line with the floor
                                          // reads clearly
            var edges: [EdgeSpec] = []

            // Edges along X — thicker on the bottom face (y == 0).
            for y in [Float(0), 1] {
                let thickness = y == 0 ? bottomT : t
                for z in [-h, h] {
                    edges.append(EdgeSpec(
                        center: SIMD3(0, y, z),
                        size: SIMD3(1, thickness, thickness)
                    ))
                }
            }
            // Edges along Y — vertical, uniform thickness.
            for x in [-h, h] {
                for z in [-h, h] {
                    edges.append(EdgeSpec(
                        center: SIMD3(x, 0.5, z),
                        size: SIMD3(t, 1, t)
                    ))
                }
            }
            // Edges along Z — thicker on the bottom face (y == 0).
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

        // MARK: Helpers

        private func raycastWorldPosition(from location: CGPoint, in arView: ARView) -> SIMD3<Float>? {
            if let strict = arView.makeRaycastQuery(
                from: location,
                allowing: .existingPlaneGeometry,
                alignment: .horizontal
            ),
               let hit = arView.session.raycast(strict).first {
                return SIMD3(
                    hit.worldTransform.columns.3.x,
                    hit.worldTransform.columns.3.y,
                    hit.worldTransform.columns.3.z
                )
            }
            if let estimated = arView.makeRaycastQuery(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ),
               let hit = arView.session.raycast(estimated).first {
                return SIMD3(
                    hit.worldTransform.columns.3.x,
                    hit.worldTransform.columns.3.y,
                    hit.worldTransform.columns.3.z
                )
            }
            return nil
        }
    }
}

// MARK: - Dimension unit helpers

/// Conversion factor from the store's configured dimension unit to metres
/// (which is what RealityKit / ARKit use internally).
enum DimensionUnitConversion {
    static func metersPerUnit(_ unit: String) -> Float {
        switch unit.lowercased() {
        case "in":  return 0.0254
        case "cm":  return 0.01
        case "mm":  return 0.001
        case "m":   return 1.0
        case "yd":  return 0.9144
        default:    return 0.0254
        }
    }

    static func sliderRange(for unit: String) -> ClosedRange<Float> {
        switch unit.lowercased() {
        case "in":  return 0.5...30.0
        case "cm":  return 1.0...75.0
        case "mm":  return 10.0...750.0
        case "m":   return 0.01...0.75
        case "yd":  return 0.02...0.83
        default:    return 0.5...30.0
        }
    }

    static func defaultDimensions(for unit: String) -> (length: Float, width: Float, height: Float) {
        switch unit.lowercased() {
        case "in":  return (8.0, 6.0, 4.0)
        case "cm":  return (20.0, 15.0, 10.0)
        case "mm":  return (200.0, 150.0, 100.0)
        case "m":   return (0.20, 0.15, 0.10)
        case "yd":  return (0.22, 0.16, 0.11)
        default:    return (8.0, 6.0, 4.0)
        }
    }
}

// MARK: - Shared chrome for AR Cuboid views

/// Small centre reticle. Hosted by the parent so it can be hidden once the
/// cuboid is placed.
struct ARCuboidReticle: View {
    let active: Bool

    var body: some View {
        let color: Color = active ? .blue : .white
        Circle()
            .stroke(color, lineWidth: 1.5)
            .frame(width: 18, height: 18)
            .overlay(Circle().fill(color).frame(width: 3, height: 3))
            .shadow(color: .black.opacity(0.5), radius: 1.5)
            .animation(.easeInOut(duration: 0.15), value: active)
    }
}

/// Small dark circular icon button used for the trash action.
struct ARCuboidCircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.5), in: Circle())
        }
    }
}

/// Large yellow "+" button used to place the cuboid. Disabled until the
/// reticle has a valid target.
struct ARCuboidPlaceButton: View {
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title.weight(.semibold))
                .foregroundStyle(active ? Color.black : Color.white.opacity(0.6))
                .frame(width: 64, height: 64)
                .background(
                    active ? AnyShapeStyle(.blue) : AnyShapeStyle(.black.opacity(0.5)),
                    in: Circle()
                )
        }
        .disabled(!active)
        .animation(.easeInOut(duration: 0.15), value: active)
    }
}
