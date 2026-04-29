import SwiftUI
import RealityKit
import ARKit

struct ARParcelSceneView: UIViewRepresentable {
    let dimensions: SIMD3<Float>
    @Binding var isPlaced: Bool
    let resetTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(isPlaced: $isPlaced)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isLightEstimationEnabled = false
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

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
        arView.renderOptions.insert(.disableGroundingShadows)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        arView.addGestureRecognizer(tap)
        context.coordinator.tapGesture = tap

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
        if context.coordinator.lastResetTrigger != resetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger
            context.coordinator.removeCuboid()
        }
        context.coordinator.updateDimensions(dimensions)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var arView: ARView?
        @Binding var isPlaced: Bool
        var dimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
        var lastResetTrigger: Int = 0

        private var cuboidAnchor: AnchorEntity?
        private var cuboidEntity: ModelEntity?
        private var installedGestures: [EntityGestureRecognizer] = []

        var tapGesture: UITapGestureRecognizer?
        var rotationGesture: UIRotationGestureRecognizer?
        private var rotationStartYaw: Float = 0

        init(isPlaced: Binding<Bool>) {
            self._isPlaced = isPlaced
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isPlaced, let arView else { return }
            let location = gesture.location(in: arView)
            guard let world = raycastWorldPosition(from: location, in: arView) else { return }

            placeCuboid(at: world)
            installGestures()
            // Deferred — writing @Binding during updateUIView is silently dropped.
            DispatchQueue.main.async { [weak self] in
                self?.isPlaced = true
            }
        }

        func removeCuboid() {
            uninstallGestures()
            if let cuboidAnchor, let arView {
                arView.scene.removeAnchor(cuboidAnchor)
            }
            cuboidAnchor = nil
            cuboidEntity = nil
            DispatchQueue.main.async { [weak self] in
                self?.isPlaced = false
            }
        }

        func updateDimensions(_ dims: SIMD3<Float>) {
            dimensions = dims
            cuboidEntity?.transform.scale = dims
        }

        private func placeCuboid(at world: SIMD3<Float>) {
            guard let arView else { return }
            let entity = ARCuboidEntity.build()
            entity.position = world
            entity.transform.scale = dimensions

            let anchor = AnchorEntity(world: matrix_identity_float4x4)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)

            cuboidAnchor = anchor
            cuboidEntity = entity
        }

        private func installGestures() {
            guard let arView, let cuboidEntity else { return }
            // Offset matches the unit cube (bottom at y=0, top at y=1).
            cuboidEntity.collision = CollisionComponent(
                shapes: [
                    .generateBox(size: SIMD3(1, 1, 1))
                        .offsetBy(translation: SIMD3(0, 0.5, 0))
                ]
            )
            installedGestures = arView.installGestures([.translation], for: cuboidEntity)
            tapGesture?.isEnabled = false
            rotationGesture?.isEnabled = true
        }

        private func uninstallGestures() {
            guard let arView else { return }
            for gesture in installedGestures {
                arView.removeGestureRecognizer(gesture)
            }
            installedGestures.removeAll()
            tapGesture?.isEnabled = true
            rotationGesture?.isEnabled = false
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let cuboidEntity else { return }
            switch gesture.state {
            case .began:
                let q = cuboidEntity.transform.rotation
                rotationStartYaw = 2 * atan2(q.imag.y, q.real)
            case .changed:
                let yaw = rotationStartYaw - Float(gesture.rotation)
                cuboidEntity.transform.rotation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
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

        private func raycastWorldPosition(from location: CGPoint, in arView: ARView) -> SIMD3<Float>? {
            if let strict = arView.makeRaycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal),
               let hit = arView.session.raycast(strict).first {
                return SIMD3(hit.worldTransform.columns.3.x, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
            }
            if let estimated = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal),
               let hit = arView.session.raycast(estimated).first {
                return SIMD3(hit.worldTransform.columns.3.x, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
            }
            return nil
        }
    }
}

// MARK: - Dimension unit helpers

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

// MARK: - Shared chrome

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
