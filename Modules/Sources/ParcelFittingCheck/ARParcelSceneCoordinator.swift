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
    private var resizeContext: ResizeContext?
    private var lastAppliedFingerPositions: (first: CGPoint, second: CGPoint)?

    /// Per-frame screen-space dead zone, in points. Below this, finger movement
    /// is treated as touch-sensor jitter and the resize update is skipped.
    private static let jitterThresholdPoints: CGFloat = 1.5

    /// Minimum allowed cuboid size on any axis, in metres. Slightly larger than
    /// the previous slider minimum (1 cm) per design intent.
    private static let minSizeMeters: Float = 0.02

    /// When Y wins the screen-space alignment race, an X or Z axis whose
    /// screen direction is close to Y's would be a plausible alternative, and
    /// the gesture engages the strict upper-half hit-test fallback. Below this
    /// ratio (second-best score / Y's score), Y is treated as the clear winner
    /// and the hit-test is skipped — vertical pinch anywhere on the cuboid
    /// resizes height. 0.7 ≈ roughly 45° of screen-direction separation.
    private static let yAxisAmbiguityThreshold: Float = 0.7

    private struct ResizeContext {
        let axis: ARCuboidEntity.Axis
        let axisWorld: SIMD3<Float>
        let cuboidCenterAtStart: SIMD3<Float>
        let planeNormal: SIMD3<Float>
        let initialScale: SIMD3<Float>
        let initialPosition: SIMD3<Float>
        let firstFinger: FingerLatch
        let secondFinger: FingerLatch
    }

    private struct FingerLatch {
        let face: ARCuboidEntity.Face
        let initialAxisDisplacement: Float
    }

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
        resizeContext = nil
        lastAppliedFingerPositions = nil
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
        if resizeContext == nil {
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
        resizeContext = nil
        lastAppliedFingerPositions = nil
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
            let currentRotation = cuboid.root.transform.rotation
            rotationStartYaw = 2 * atan2(currentRotation.imag.y, currentRotation.real)
            resizeContext = nil
            lastAppliedFingerPositions = nil
        case .changed:
            switch gesture.mode {
            case .undecided:
                break
            case .rotate:
                let yaw = rotationStartYaw - Float(gesture.rotationFromStart)
                cuboid.root.transform.rotation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            case .resize:
                if resizeContext == nil { setupResize(gesture: gesture) }
                applyResize(gesture: gesture)
            }
        case .ended, .cancelled, .failed:
            resizeContext = nil
            lastAppliedFingerPositions = nil
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
        let highlighted: Set<ARCuboidEntity.Face> = resizeContext.map {
            Set([$0.firstFinger.face, $0.secondFinger.face])
        } ?? []
        cuboid.updateMaterials(
            cameraPosition: arView.cameraTransform.translation,
            highlightedFaces: highlighted
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
}

// MARK: - Resize

private extension ARParcelSceneCoordinator {
    func setupResize(gesture: TwoFingerCuboidGesture) {
        guard let arView, let cuboid else { return }

        let yaw = currentYaw(of: cuboid.root)
        let xAxis = SIMD3<Float>(cos(yaw), 0, -sin(yaw))
        let yAxis = SIMD3<Float>(0, 1, 0)
        let zAxis = SIMD3<Float>(sin(yaw), 0, cos(yaw))

        let scale = cuboid.root.transform.scale
        let position = cuboid.root.position
        // The cuboid's local Y goes 0…1 (root is at the bottom); X and Z are
        // centred on the root, so the geometric centre sits half-a-height up.
        let cuboidCenter = position + 0.5 * scale.y * yAxis

        guard let pick = pickActiveAxis(
            arView: arView,
            cuboidCenter: cuboidCenter,
            xAxisWorld: xAxis,
            yAxisWorld: yAxis,
            zAxisWorld: zAxis,
            firstScreen: gesture.startLocations.first,
            secondScreen: gesture.startLocations.second
        ) else { return }
        let chosenAxis = pick.axis

        // For Y, a vertical screen-space pinch is the natural cue. We accept
        // it without a hit-test when Y dominates the alignment race; only when
        // X or Z projects close to Y's screen direction do we fall back to
        // requiring at least one finger on the upper half of the cuboid as
        // explicit confirmation.
        if chosenAxis == .y && pick.ambiguity > Self.yAxisAmbiguityThreshold {
            let firstUpper = hitTestCuboidUpperHalf(arView: arView, screenPoint: gesture.startLocations.first)
            let secondUpper = hitTestCuboidUpperHalf(arView: arView, screenPoint: gesture.startLocations.second)
            guard firstUpper || secondUpper else { return }
        }

        let axisWorld: SIMD3<Float>
        switch chosenAxis {
        case .x: axisWorld = xAxis
        case .y: axisWorld = yAxis
        case .z: axisWorld = zAxis
        }

        let mat = arView.cameraTransform.matrix
        let cameraForward = -SIMD3<Float>(mat.columns.2.x, mat.columns.2.y, mat.columns.2.z)

        guard let hit0 = projectToPlane(
            arView: arView,
            screenPoint: gesture.startLocations.first,
            planePoint: cuboidCenter,
            planeNormal: cameraForward
        ),
              let hit1 = projectToPlane(
                arView: arView,
                screenPoint: gesture.startLocations.second,
                planePoint: cuboidCenter,
                planeNormal: cameraForward
              ) else { return }

        let disp0 = simd_dot(hit0 - cuboidCenter, axisWorld)
        let disp1 = simd_dot(hit1 - cuboidCenter, axisWorld)
        // Make the finger with the larger axis projection drive the +face and
        // the other drive the -face, even when both fingers are on the same
        // side of the cuboid centre.
        let firstIsPositiveSide = disp0 >= disp1

        let firstLatch = FingerLatch(
            face: firstIsPositiveSide
                ? .positiveSide(of: chosenAxis)
                : .negativeSide(of: chosenAxis),
            initialAxisDisplacement: disp0
        )
        let secondLatch = FingerLatch(
            face: firstIsPositiveSide
                ? .negativeSide(of: chosenAxis)
                : .positiveSide(of: chosenAxis),
            initialAxisDisplacement: disp1
        )

        resizeContext = ResizeContext(
            axis: chosenAxis,
            axisWorld: axisWorld,
            cuboidCenterAtStart: cuboidCenter,
            planeNormal: cameraForward,
            initialScale: scale,
            initialPosition: position,
            firstFinger: firstLatch,
            secondFinger: secondLatch
        )
        lastAppliedFingerPositions = gesture.startLocations
    }

    func applyResize(gesture: TwoFingerCuboidGesture) {
        guard let arView, let cuboid, let context = resizeContext else { return }

        if let last = lastAppliedFingerPositions {
            let firstDelta = hypot(
                gesture.currentLocations.first.x - last.first.x,
                gesture.currentLocations.first.y - last.first.y
            )
            let secondDelta = hypot(
                gesture.currentLocations.second.x - last.second.x,
                gesture.currentLocations.second.y - last.second.y
            )
            if firstDelta < Self.jitterThresholdPoints && secondDelta < Self.jitterThresholdPoints {
                return
            }
        }

        guard let hit0 = projectToPlane(
            arView: arView,
            screenPoint: gesture.currentLocations.first,
            planePoint: context.cuboidCenterAtStart,
            planeNormal: context.planeNormal
        ),
              let hit1 = projectToPlane(
                arView: arView,
                screenPoint: gesture.currentLocations.second,
                planePoint: context.cuboidCenterAtStart,
                planeNormal: context.planeNormal
              ) else { return }

        let disp0 = simd_dot(hit0 - context.cuboidCenterAtStart, context.axisWorld)
        let disp1 = simd_dot(hit1 - context.cuboidCenterAtStart, context.axisWorld)

        let firstAxisDelta = disp0 - context.firstFinger.initialAxisDisplacement
        let secondAxisDelta = disp1 - context.secondFinger.initialAxisDisplacement

        let firstOutward = signedOutwardDelta(face: context.firstFinger.face, axisDelta: firstAxisDelta)
        let secondOutward = signedOutwardDelta(face: context.secondFinger.face, axisDelta: secondAxisDelta)

        let outwardPositive: Float
        let outwardNegative: Float
        if context.firstFinger.face.isPositiveSide {
            outwardPositive = firstOutward
            outwardNegative = secondOutward
        } else {
            outwardPositive = secondOutward
            outwardNegative = firstOutward
        }

        let axisIndex = simdIndex(for: context.axis)
        let oldAxisScale = context.initialScale[axisIndex]
        let totalDelta = outwardPositive + outwardNegative
        let unclampedScale = oldAxisScale + totalDelta
        let newAxisScale = max(unclampedScale, Self.minSizeMeters)

        // When the user shrinks past the floor, scale back the per-finger
        // contributions proportionally so the geometric centre tracks both
        // fingers smoothly (the cuboid stops shrinking but does not jump).
        let actualTotal = newAxisScale - oldAxisScale
        let scaleFactor: Float = abs(totalDelta) < 1e-6 ? 1 : actualTotal / totalDelta
        let actualPositive = outwardPositive * scaleFactor
        let actualNegative = outwardNegative * scaleFactor

        var newScale = context.initialScale
        newScale[axisIndex] = newAxisScale

        var newPosition = context.initialPosition
        // Y axis keeps the root at the floor (cuboid local Y is 0…1, so growing
        // scale.y already moves only the top). X/Z are centred on the root, so
        // an asymmetric resize requires shifting the root by half the imbalance.
        // The cap |shift| ≤ |scale change| / 2 prevents pure translation: when
        // both fingers move in the same direction, scale stays put and the cap
        // collapses to zero, so the cuboid does not slide. Single-finger drag
        // is the only sanctioned way to move it.
        if context.axis != .y {
            let centerShift = (actualPositive - actualNegative) * 0.5
            let maxShift = abs(actualTotal) * 0.5
            let clampedShift = max(-maxShift, min(maxShift, centerShift))
            newPosition += clampedShift * context.axisWorld
        }

        cuboid.root.transform.scale = newScale
        cuboid.root.position = newPosition
        lastAppliedFingerPositions = gesture.currentLocations

        dimensions = newScale
        onDimensionsChanged?(newScale)
    }

    func pickActiveAxis(
        arView: ARView,
        cuboidCenter: SIMD3<Float>,
        xAxisWorld: SIMD3<Float>,
        yAxisWorld: SIMD3<Float>,
        zAxisWorld: SIMD3<Float>,
        firstScreen: CGPoint,
        secondScreen: CGPoint
    ) -> (axis: ARCuboidEntity.Axis, ambiguity: Float)? {
        guard let centerScreen = arView.project(cuboidCenter),
              let xEnd = arView.project(cuboidCenter + 0.1 * xAxisWorld),
              let yEnd = arView.project(cuboidCenter + 0.1 * yAxisWorld),
              let zEnd = arView.project(cuboidCenter + 0.1 * zAxisWorld) else { return nil }

        let xDir = CGPoint(x: xEnd.x - centerScreen.x, y: xEnd.y - centerScreen.y)
        let yDir = CGPoint(x: yEnd.x - centerScreen.x, y: yEnd.y - centerScreen.y)
        let zDir = CGPoint(x: zEnd.x - centerScreen.x, y: zEnd.y - centerScreen.y)
        let fingerDir = CGPoint(x: secondScreen.x - firstScreen.x, y: secondScreen.y - firstScreen.y)

        let candidates: [(ARCuboidEntity.Axis, CGPoint)] = [(.x, xDir), (.y, yDir), (.z, zDir)]
        var bestAxis: ARCuboidEntity.Axis?
        var bestScore: CGFloat = 0
        var secondBestScore: CGFloat = 0
        for (axis, dir) in candidates {
            let length = max(hypot(dir.x, dir.y), 1)
            let score = abs(fingerDir.x * dir.x + fingerDir.y * dir.y) / length
            if score > bestScore {
                secondBestScore = bestScore
                bestScore = score
                bestAxis = axis
            } else if score > secondBestScore {
                secondBestScore = score
            }
        }
        guard let bestAxis else { return nil }
        let ambiguity: Float = bestScore > 0 ? Float(secondBestScore / bestScore) : 0
        return (bestAxis, ambiguity)
    }

    func signedOutwardDelta(face: ARCuboidEntity.Face, axisDelta: Float) -> Float {
        if face == .negativeY { return 0 }
        return face.isPositiveSide ? axisDelta : -axisDelta
    }

    func currentYaw(of entity: ModelEntity) -> Float {
        let rotation = entity.transform.rotation
        return 2 * atan2(rotation.imag.y, rotation.real)
    }

    func projectToPlane(
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

    func simdIndex(for axis: ARCuboidEntity.Axis) -> Int {
        switch axis {
        case .x: return 0
        case .y: return 1
        case .z: return 2
        }
    }

    /// Returns true when `screenPoint` ray-casts onto the upper half of the
    /// cuboid (any face, but above the local-Y midline). The collision shape
    /// is a unit cube spanning local Y 0…1, so the threshold is 0.5.
    func hitTestCuboidUpperHalf(arView: ARView, screenPoint: CGPoint) -> Bool {
        guard let cuboid else { return false }
        let hits = arView.hitTest(screenPoint, query: .nearest, mask: .default)
        guard let hit = hits.first(where: { $0.entity == cuboid.root }) else { return false }
        let localPosition = cuboid.root.convert(position: hit.position, from: nil)
        return localPosition.y > 0.5
    }
}
