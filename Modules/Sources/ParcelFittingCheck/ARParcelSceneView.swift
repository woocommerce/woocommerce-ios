import SwiftUI
import RealityKit
import ARKit

struct ARParcelSceneView: UIViewRepresentable {
    let dimensions: SIMD3<Float>
    @Binding var isPlaced: Bool
    @Binding var isARReady: Bool
    let resetTrigger: Int
    var onDimensionsChanged: ((SIMD3<Float>) -> Void)?

    func makeCoordinator() -> ARParcelSceneCoordinator {
        let coordinator = ARParcelSceneCoordinator()
        let placedBinding = $isPlaced
        let readyBinding = $isARReady
        coordinator.onPlaced = { placedBinding.wrappedValue = true }
        coordinator.onRemoved = { placedBinding.wrappedValue = false }
        coordinator.onARReady = { readyBinding.wrappedValue = true }
        coordinator.onARLost = { readyBinding.wrappedValue = false }
        return coordinator
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        configureSession(for: arView)
        addCoachingOverlay(to: arView, coordinator: context.coordinator)
        addGestures(to: arView, coordinator: context.coordinator)
        context.coordinator.arView = arView
        context.coordinator.dimensions = dimensions
        context.coordinator.onDimensionsChanged = onDimensionsChanged
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.lastResetTrigger != resetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger
            context.coordinator.removeCuboid()
        }
        context.coordinator.onDimensionsChanged = onDimensionsChanged
        context.coordinator.updateDimensions(dimensions)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARParcelSceneCoordinator) {
        coordinator.tearDown()
        uiView.session.pause()
    }
}

private extension ARParcelSceneView {
    func configureSession(for arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isLightEstimationEnabled = false
        arView.session.run(config)
        // Mesh-based occlusion is intentionally off: on LIDAR devices it would
        // hide wireframe edges behind objects placed inside the cuboid, which
        // defeats the fit-check.
        arView.environment.sceneUnderstanding.options = []
        arView.renderOptions.insert(.disableGroundingShadows)
    }

    func addCoachingOverlay(to arView: ARView, coordinator: ARParcelSceneCoordinator) {
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.delegate = coordinator
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
        coaching.setActive(true, animated: true)
    }

    func addGestures(to arView: ARView, coordinator: ARParcelSceneCoordinator) {
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(ARParcelSceneCoordinator.handleTap(_:)))
        tap.delegate = coordinator
        arView.addGestureRecognizer(tap)
        coordinator.tapGesture = tap

        let twoFinger = TwoFingerCuboidGesture(target: coordinator, action: #selector(ARParcelSceneCoordinator.handleTwoFingerGesture(_:)))
        twoFinger.delegate = coordinator
        twoFinger.isEnabled = false
        arView.addGestureRecognizer(twoFinger)
        coordinator.twoFingerGesture = twoFinger
    }
}

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
