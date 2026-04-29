import RealityKit
import ARKit
import SwiftUI

final class ARParcelSceneCoordinator: NSObject, UIGestureRecognizerDelegate {
    weak var arView: ARView?
    var dimensions: SIMD3<Float> = SIMD3(0.20, 0.10, 0.15)
    var lastResetTrigger: Int = 0

    var onPlaced: (() -> Void)?
    var onRemoved: (() -> Void)?

    private var placed = false
    private var cuboidAnchor: AnchorEntity?
    private var cuboidEntity: ModelEntity?
    private var installedGestures: [EntityGestureRecognizer] = []

    var tapGesture: UITapGestureRecognizer?
    var rotationGesture: UIRotationGestureRecognizer?
    private var rotationStartYaw: Float = 0

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
        if let cuboidAnchor, let arView {
            arView.scene.removeAnchor(cuboidAnchor)
        }
        cuboidAnchor = nil
        cuboidEntity = nil
        placed = false
        onRemoved?()
    }

    func updateDimensions(_ dims: SIMD3<Float>) {
        dimensions = dims
        cuboidEntity?.transform.scale = dims
    }

    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let cuboidEntity else { return }
        switch gesture.state {
        case .began:
            let currentRotation = cuboidEntity.transform.rotation
            rotationStartYaw = 2 * atan2(currentRotation.imag.y, currentRotation.real)
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
}

private extension ARParcelSceneCoordinator {
    func placeCuboid(at world: SIMD3<Float>) {
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

    func installGestures() {
        guard let arView, let cuboidEntity else { return }
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

    func uninstallGestures() {
        guard let arView else { return }
        for gesture in installedGestures {
            arView.removeGestureRecognizer(gesture)
        }
        installedGestures.removeAll()
        tapGesture?.isEnabled = true
        rotationGesture?.isEnabled = false
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
}
