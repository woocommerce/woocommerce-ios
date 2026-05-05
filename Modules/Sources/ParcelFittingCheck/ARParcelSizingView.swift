import SwiftUI

struct ARParcelSizingView: View {
    private let onCancel: () -> Void
    private let onConfirm: (ParcelDimensions) -> Void

    @State private var viewModel: ARParcelSizingViewModel
    @State private var isARReady: Bool = false
    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(unit: UnitLength,
         initial: ParcelDimensions? = nil,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (ParcelDimensions) -> Void) {
        self._viewModel = State(initialValue: ARParcelSizingViewModel(unit: unit, initial: initial))
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
                onDimensionsChanged: { viewModel.update(fromMeters: $0) }
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
    }

    private var headerMessage: String? {
        if isPlaced {
            return viewModel.dimensionsLabel
        }
        if isARReady {
            return "Tap on the surface to place the fitting box"
        }
        return nil
    }

    private var topToolbar: some View {
        ARCuboidSceneToolbar(onCancel: onCancel, onReset: isPlaced ? { resetTrigger += 1 } : nil)
    }

    private var confirmButton: some View {
        Button { onConfirm(viewModel.confirmedDimensions) } label: {
            Text("Use these dimensions")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.blue, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
