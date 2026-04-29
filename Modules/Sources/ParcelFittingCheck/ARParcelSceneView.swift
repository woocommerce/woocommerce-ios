import SwiftUI
import RealityKit
import ARKit

struct ARParcelSceneView: UIViewRepresentable {
    let dimensions: SIMD3<Float>
    @Binding var isPlaced: Bool
    let resetTrigger: Int

    func makeCoordinator() -> ARParcelSceneCoordinator {
        let coordinator = ARParcelSceneCoordinator()
        let placedBinding = $isPlaced
        coordinator.onPlaced = { placedBinding.wrappedValue = true }
        coordinator.onRemoved = { placedBinding.wrappedValue = false }
        return coordinator
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        configureSession(for: arView)
        addCoachingOverlay(to: arView)
        addGestures(to: arView, coordinator: context.coordinator)
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

    static func dismantleUIView(_ uiView: ARView, coordinator: ARParcelSceneCoordinator) {
        uiView.session.pause()
    }
}

private extension ARParcelSceneView {
    func configureSession(for arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isLightEstimationEnabled = false
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)
        arView.environment.sceneUnderstanding.options = [.occlusion]
        arView.renderOptions.insert(.disableGroundingShadows)
    }

    func addCoachingOverlay(to arView: ARView) {
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
    }

    func addGestures(to arView: ARView, coordinator: ARParcelSceneCoordinator) {
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(ARParcelSceneCoordinator.handleTap(_:)))
        tap.delegate = coordinator
        arView.addGestureRecognizer(tap)
        coordinator.tapGesture = tap

        let rotation = UIRotationGestureRecognizer(target: coordinator, action: #selector(ARParcelSceneCoordinator.handleRotation(_:)))
        rotation.delegate = coordinator
        rotation.isEnabled = false
        arView.addGestureRecognizer(rotation)
        coordinator.rotationGesture = rotation
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
