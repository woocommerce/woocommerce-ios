import RealityKit
import ARKit
import SwiftUI
import Combine

final class ARParcelSceneCoordinator: NSObject, UIGestureRecognizerDelegate, ARCoachingOverlayViewDelegate {
    weak var arView: ARView?
    var dimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
    private let initialDimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
    var lastResetTrigger: Int = 0
    private var hasPlacedOnce = false

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
    var twoFingerGesture: TwoFingerCuboidGestureRecognizer?
    private var rotationStartYaw: Float = 0
    private let resizeInteraction = CuboidResizeInteraction()
    private var cachedResizeEnvironment: CuboidResizeInteraction.Environment?

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !placed, let arView else { return }
        let location = gesture.location(in: arView)
        guard let world = raycastWorldPosition(from: location, in: arView) else { return }

        placeCuboid(at: world)
        installGestures()
        placed = true
        hasPlacedOnce = true
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
        dimensions = initialDimensions
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

    @objc func handleTwoFingerGesture(_ gesture: TwoFingerCuboidGestureRecognizer) {
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
    enum Constants {
        /// Cuboid local Y is 0…1 with the root at the floor. Anything above
        /// this threshold counts as the upper half for the height-resize
        /// hit-test fallback.
        static let upperHalfYThreshold: Float = 0.5

        /// Vertical offset of the unit-cube collision shape so it spans local
        /// Y 0…1 (matching the wireframe geometry). Half-height upward from
        /// the root anchor.
        static let collisionShapeYOffset: Float = 0.5
    }

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
        guard let arView else { return }
        cuboid?.updateMaterials(
            cameraPosition: arView.cameraTransform.translation,
            highlightedFaces: resizeInteraction.highlightedFaces
        )
    }

    func installGestures() {
        guard let arView, let cuboid else { return }
        cuboid.root.collision = CollisionComponent(
            shapes: [
                .generateBox(size: SIMD3(1, 1, 1))
                    .offsetBy(translation: SIMD3(0, Constants.collisionShapeYOffset, 0))
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
        // Estimated planes are only used for the very first placement (before
        // ARKit has detected real geometry). After trash, real planes should
        // still be available — falling back to estimates here would place the
        // cuboid at an unreliable height.
        if !hasPlacedOnce,
           let estimated = arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal),
           let hit = arView.session.raycast(estimated).first {
            return SIMD3(hit.worldTransform.columns.3.x, hit.worldTransform.columns.3.y, hit.worldTransform.columns.3.z)
        }
        return nil
    }

    func applyResize(gesture: TwoFingerCuboidGestureRecognizer, cuboid: ARCuboidEntity) {
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
    ) -> CuboidResizeInteraction.BeginInput {
        CuboidResizeInteraction.BeginInput(
            cuboidPosition: cuboid.root.position,
            cuboidScale: cuboid.root.transform.scale,
            cuboidRotation: cuboid.root.transform.rotation,
            fingers: fingers
        )
    }

    func makeResizeEnvironment() -> CuboidResizeInteraction.Environment {
        CuboidResizeInteraction.Environment(
            projectToScreen: { [weak self] world in
                guard let arView = self?.arView else { return nil }
                return arView.project(world)
            },
            isUpperHalfHit: { [weak self] screen in
                guard let self, let arView = self.arView, let cuboid = self.cuboid else { return false }
                let hits = arView.hitTest(screen, query: .nearest, mask: .default)
                guard let hit = hits.first(where: { $0.entity == cuboid.root }) else { return false }
                let localPosition = cuboid.root.convert(position: hit.position, from: nil)
                return localPosition.y > Constants.upperHalfYThreshold
            }
        )
    }

    func yaw(of rotation: simd_quatf) -> Float {
        2 * atan2(rotation.imag.y, rotation.real)
    }
}
