import SwiftUI

struct ARParcelSizingView: View {
    private let onCancel: () -> Void
    private let onConfirm: (ParcelDimensions) -> Void

    @State private var viewModel: ARParcelSizingViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var isARReady: Bool = false
    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(unit: UnitLength,
         initial: ParcelDimensions? = nil,
         analytics: ParcelFittingAnalyticsTracking,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (ParcelDimensions) -> Void) {
        self._viewModel = State(initialValue: ARParcelSizingViewModel(unit: unit, initial: initial, analytics: analytics))
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        ZStack {
            ARParcelSceneView(
                dimensions: viewModel.dimensionsInMeters,
                isPlaced: $isPlaced,
                isARReady: $isARReady,
                resetTrigger: resetTrigger,
                onDimensionsChanged: { viewModel.update(fromMeters: $0) },
                onGestureCompleted: { viewModel.recordGestureCompleted(mode: $0) }
            )
            .ignoresSafeArea()

            VStack {
                topToolbar

                if let message = headerMessage {
                    Text(message)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer()

                if isPlaced {
                    confirmButton
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPlaced)
        }
        .background(Color.black)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { resetWithoutTracking() }
        }
        .onChange(of: isARReady) { _, ready in
            if ready { viewModel.recordARReady() }
        }
        .onChange(of: isPlaced) { _, placed in
            if placed { viewModel.trackBoxPlaced() }
        }
    }

    private func userReset() {
        resetTrigger += 1
        viewModel.resetToDefaults()
        viewModel.recordReset()
    }

    private func resetWithoutTracking() {
        resetTrigger += 1
        viewModel.resetToDefaults()
    }

    private var headerMessage: String? {
        if isPlaced {
            return viewModel.dimensionsLabel
        }
        if isARReady {
            return Localization.placementHint
        }
        return nil
    }

    private var topToolbar: some View {
        ARCuboidSceneToolbar(
            onCancel: {
                viewModel.trackSizingCanceled(hadPlacedBox: isPlaced, arReady: isARReady)
                onCancel()
            },
            onReset: isPlaced ? { userReset() } : nil
        )
    }

    private var confirmButton: some View {
        Button {
            viewModel.trackSizingCompleted()
            onConfirm(viewModel.confirmedDimensions)
        } label: {
            Text(Localization.useTheseDimensions)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

private extension ARParcelSizingView {
    enum Localization {
        static let placementHint = NSLocalizedString(
            "parcelFitting.sizing.placementHint",
            value: "Tap on the surface to place the fitting box",
            comment: "Hint text shown when the AR surface is ready for cuboid placement")
        static let useTheseDimensions = NSLocalizedString(
            "parcelFitting.sizing.useTheseDimensions",
            value: "Use these dimensions",
            comment: "Button to confirm the measured dimensions in the AR sizing view")
    }
}
