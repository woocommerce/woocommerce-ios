import RealityKit
import ARKit
import SwiftUI
import Combine

final class ARParcelSceneCoordinator: NSObject, UIGestureRecognizerDelegate, ARCoachingOverlayViewDelegate {
    weak var arView: ARView?
    var dimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
    var lastResetTrigger: Int = 0

    var onPlaced: (() -> Void)?
    var onRemoved: (() -> Void)?
    var onARReady: (() -> Void)?
    var onARLost: (() -> Void)?
    var onDimensionsChanged: ((SIMD3<Float>) -> Void)?

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        onARReady?()
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        onARLost?()
    }

    private var placed = false
    private var cuboidAnchor: AnchorEntity?
    private var cuboid: ARCuboidEntity?
    private var sceneSubscription: Cancellable?
    private var installedGestures: [EntityGestureRecognizer] = []

    var tapGesture: UITapGestureRecognizer?
    var twoFingerGesture: TwoFingerCuboidGesture?
    private var rotationStartYaw: Float = 0
    private let resizeInteraction = ParcelResizeInteraction()
    private var cachedResizeEnvironment: ParcelResizeInteraction.Environment?

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !placed, let arView else { return }
        let location = gesture.location(in: arView)
        guard let world = raycastWorldPosition(from: location, in: arView) else { return }

        placeCuboid(at: world)
        installGestures()
        placed = true
        onPlaced?()
    }

    func removeCuboid() {
        uninstallGestures()
        sceneSubscription?.cancel()
        sceneSubscription = nil
        if let cuboidAnchor, let arView {
            arView.scene.removeAnchor(cuboidAnchor)
        }
        cuboidAnchor = nil
        cuboid = nil
        resizeInteraction.end()
        cachedResizeEnvironment = nil
        placed = false
        // Deferred — removeCuboid is called from updateUIView, which runs
        // inside SwiftUI's render pass. Binding writes during a render pass
        // are silently dropped.
        DispatchQueue.main.async { [weak self] in
            self?.onRemoved?()
        }
    }

    func updateDimensions(_ dims: SIMD3<Float>) {
        guard dims != dimensions else { return }
        dimensions = dims
        // While a gesture-driven resize is active the coordinator owns the cuboid
        // scale; ignore external echoes coming back through the SwiftUI binding.
        if !resizeInteraction.isActive {
            cuboid?.root.transform.scale = dims
        }
    }

    func tearDown() {
        uninstallGestures()
        sceneSubscription?.cancel()
        sceneSubscription = nil
        if let cuboidAnchor, let arView {
            arView.scene.removeAnchor(cuboidAnchor)
        }
        cuboidAnchor = nil
        cuboid = nil
        resizeInteraction.end()
        cachedResizeEnvironment = nil
        arView = nil
        onPlaced = nil
        onRemoved = nil
        onARReady = nil
        onARLost = nil
        onDimensionsChanged = nil
    }

    @objc func handleTwoFingerGesture(_ gesture: TwoFingerCuboidGesture) {
        guard let cuboid else { return }
        switch gesture.state {
        case .began:
            // RealityKit's installed translation gesture would otherwise fire
            // concurrently and write to cuboid.root.position from the touch
            // centroid, fighting our resize/rotate writes (most visibly during
            // height resize, where we keep position locked).
            setInstalledGesturesEnabled(false)
            rotationStartYaw = yaw(of: cuboid.root.transform.rotation)
            resizeInteraction.end()
            cachedResizeEnvironment = makeResizeEnvironment()
        case .changed:
            switch gesture.mode {
            case .undecided:
                break
            case .rotate:
                let yaw = rotationStartYaw - Float(gesture.rotationFromStart)
                cuboid.root.transform.rotation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            case .resize:
                applyResize(gesture: gesture, cuboid: cuboid)
            }
        case .ended, .cancelled, .failed:
            setInstalledGesturesEnabled(true)
            resizeInteraction.end()
            cachedResizeEnvironment = nil
        default:
            break
        }
    }

    private func setInstalledGesturesEnabled(_ enabled: Bool) {
        for gesture in installedGestures {
            gesture.isEnabled = enabled
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

private extension ARParcelSceneCoordinator {
    func placeCuboid(at world: SIMD3<Float>) {
        guard let arView else { return }
        let entity = ARCuboidEntity.build()
        entity.root.position = world
        entity.root.transform.scale = dimensions

        let anchor = AnchorEntity(world: matrix_identity_float4x4)
        anchor.addChild(entity.root)
        arView.scene.addAnchor(anchor)

        cuboidAnchor = anchor
        cuboid = entity

        sceneSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            self?.updateMaterials()
        }
    }

    func updateMaterials() {
        guard let arView, let cuboid else { return }
        cuboid.updateMaterials(
            cameraPosition: arView.cameraTransform.translation,
            highlightedFaces: resizeInteraction.highlightedFaces
        )
    }

    func installGestures() {
        guard let arView, let cuboid else { return }
        cuboid.root.collision = CollisionComponent(
            shapes: [
                .generateBox(size: SIMD3(1, 1, 1))
                    .offsetBy(translation: SIMD3(0, 0.5, 0))
            ]
        )
        installedGestures = arView.installGestures([.translation], for: cuboid.root)
        tapGesture?.isEnabled = false
        twoFingerGesture?.isEnabled = true
    }

    func uninstallGestures() {
        guard let arView else { return }
        for gesture in installedGestures {
            arView.removeGestureRecognizer(gesture)
        }
        installedGestures.removeAll()
        tapGesture?.isEnabled = true
        twoFingerGesture?.isEnabled = false
    }

    func raycastWorldPosition(from location: CGPoint, in arView: ARView) -> SIMD3<Float>? {
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

    func applyResize(gesture: TwoFingerCuboidGesture, cuboid: ARCuboidEntity) {
        guard let env = cachedResizeEnvironment else { return }
        if !resizeInteraction.isActive {
            resizeInteraction.begin(
                input: makeBeginInput(cuboid: cuboid, fingers: gesture.startLocations),
                environment: env
            )
        }
        guard let output = resizeInteraction.update(fingers: gesture.currentLocations, environment: env) else { return }

        cuboid.root.transform.scale = output.scale
        cuboid.root.position = output.position
        dimensions = output.scale
        onDimensionsChanged?(output.scale)
    }

    func makeBeginInput(
        cuboid: ARCuboidEntity,
        fingers: (first: CGPoint, second: CGPoint)
    ) -> ParcelResizeInteraction.BeginInput {
        ParcelResizeInteraction.BeginInput(
            cuboidPosition: cuboid.root.position,
            cuboidScale: cuboid.root.transform.scale,
            cuboidYaw: yaw(of: cuboid.root.transform.rotation),
            cameraForward: cameraForward(),
            fingers: fingers
        )
    }

    func makeResizeEnvironment() -> ParcelResizeInteraction.Environment {
        ParcelResizeInteraction.Environment(
            projectToScreen: { [weak self] world in
                guard let arView = self?.arView else { return nil }
                return arView.project(world)
            },
            projectToPlane: { [weak self] screen, planePoint, planeNormal in
                guard let arView = self?.arView else { return nil }
                return Self.projectToPlane(
                    arView: arView,
                    screenPoint: screen,
                    planePoint: planePoint,
                    planeNormal: planeNormal
                )
            },
            isUpperHalfHit: { [weak self] screen in
                guard let self, let arView = self.arView, let cuboid = self.cuboid else { return false }
                let hits = arView.hitTest(screen, query: .nearest, mask: .default)
                guard let hit = hits.first(where: { $0.entity == cuboid.root }) else { return false }
                let localPosition = cuboid.root.convert(position: hit.position, from: nil)
                return localPosition.y > 0.5
            }
        )
    }

    func yaw(of rotation: simd_quatf) -> Float {
        2 * atan2(rotation.imag.y, rotation.real)
    }

    func cameraForward() -> SIMD3<Float> {
        guard let arView else { return SIMD3(0, 0, -1) }
        let mat = arView.cameraTransform.matrix
        return -SIMD3<Float>(mat.columns.2.x, mat.columns.2.y, mat.columns.2.z)
    }

    static func projectToPlane(
        arView: ARView,
        screenPoint: CGPoint,
        planePoint: SIMD3<Float>,
        planeNormal: SIMD3<Float>
    ) -> SIMD3<Float>? {
        guard let ray = arView.ray(through: screenPoint) else { return nil }
        let denom = simd_dot(ray.direction, planeNormal)
        guard abs(denom) > 1e-6 else { return nil }
        let t = simd_dot(planePoint - ray.origin, planeNormal) / denom
        guard t > 0 else { return nil }
        return ray.origin + t * ray.direction
    }
}
