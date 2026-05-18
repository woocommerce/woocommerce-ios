import SwiftUI

struct ARParcelSizingView: View {
    private let onCancel: () -> Void
    private let onConfirm: (ParcelDimensions) -> Void
    private let isSessionActive: Bool

    @State private var viewModel: ARParcelSizingViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var isARReady: Bool = false
    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(unit: UnitLength,
         initial: ParcelDimensions? = nil,
         analytics: ParcelFittingAnalyticsTracking,
         isSessionActive: Bool = true,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (ParcelDimensions) -> Void) {
        self._viewModel = State(initialValue: ARParcelSizingViewModel(unit: unit, initial: initial, analytics: analytics))
        self.isSessionActive = isSessionActive
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    private var phase: ARPhase {
        if isPlaced { return .placed(hintsVisible: viewModel.hintsVisible) }
        if isARReady { return .awaitingTap }
        return .detecting
    }

    var body: some View {
        ZStack {
            ARParcelSceneView(
                dimensions: viewModel.dimensionsInMeters,
                isPlaced: $isPlaced,
                isARReady: $isARReady,
                resetTrigger: resetTrigger,
                isSessionActive: isSessionActive,
                onDimensionsChanged: { viewModel.update(fromMeters: $0) },
                onGestureCompleted: { viewModel.recordGestureCompleted(mode: $0) }
            )
            .ignoresSafeArea()

            VStack {
                topToolbar

                coachingContent
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                if isPlaced {
                    ARSizingFooterHUD(
                        dimensions: viewModel.dimensions,
                        unit: viewModel.unit,
                        hintsVisible: viewModel.hintsVisible,
                        onShowHints: { viewModel.showHints() },
                        onConfirm: {
                            viewModel.trackSizingCompleted()
                            onConfirm(viewModel.dimensions)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(Self.cardTransition)
                }
            }
            .animation(.easeOut(duration: 0.22), value: phase)
            .animation(.easeOut(duration: 0.22), value: viewModel.hintsVisible)
        }
        .background(Color.black)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { resetWithoutTracking() }
        }
        .onChange(of: isSessionActive) { _, active in
            if active {
                resetWithoutTracking()
                isARReady = false
            }
        }
        .onChange(of: isARReady) { _, ready in
            if ready { viewModel.recordARReady() }
        }
        .onChange(of: isPlaced) { _, placed in
            if placed {
                viewModel.trackBoxPlaced()
                viewModel.onBoxPlaced()
            }
        }
    }

    @ViewBuilder
    private var coachingContent: some View {
        switch phase {
        case .detecting:
            EmptyView()
        case .awaitingTap:
            ARTapHintCard()
                .transition(Self.cardTransition)
        case .placed(hintsVisible: true):
            ARCoachCard(onDismiss: { viewModel.dismissHints() })
                .transition(Self.cardTransition)
        case .placed(hintsVisible: false):
            EmptyView()
        }
    }

    private static let cardTransition: AnyTransition = .opacity
        .combined(with: .scale(scale: 0.97, anchor: .top))
        .combined(with: .offset(y: -6))

    private func userReset() {
        resetTrigger += 1
        viewModel.resetToDefaults()
        viewModel.recordReset()
    }

    private func resetWithoutTracking() {
        resetTrigger += 1
        viewModel.resetToDefaults()
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
}
