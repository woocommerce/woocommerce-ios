import SwiftUI

struct ARParcelSizingView: View {
    private let onCancel: () -> Void
    private let onConfirm: (ParcelDimensions) -> Void

    @State private var viewModel: ARParcelSizingViewModel
    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(unit: DimensionUnit,
         initial: ParcelDimensions = .unset,
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
                resetTrigger: resetTrigger
            )
            .ignoresSafeArea()

            VStack {
                topToolbar

                if !isPlaced {
                    Text("Tap on the surface to place the fitting box")
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                Spacer()

                bottomControls
            }
            .animation(.easeInOut(duration: 0.2), value: isPlaced)
        }
        .background(Color.black)
        .onAppear {
            viewModel.resolveDefaults()
        }
    }

    private var topToolbar: some View {
        HStack {
            ARCuboidCircleIconButton(systemName: "xmark", action: onCancel)
            Spacer()
            if isPlaced {
                ARCuboidCircleIconButton(systemName: "trash") { resetTrigger += 1 }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var bottomControls: some View {
        if isPlaced {
            VStack(spacing: 14) {
                slider(label: "Length", value: $viewModel.dimensions.length)
                slider(label: "Width", value: $viewModel.dimensions.width)
                slider(label: "Height", value: $viewModel.dimensions.height)

                Button { onConfirm(viewModel.confirmedDimensions) } label: {
                    Text("Use these dimensions")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.black)
                }
            }
            .padding(16)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private func slider(label: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text(String(format: "%.1f %@", value.wrappedValue, viewModel.unit.displayLabel))
                    .font(.subheadline.monospacedDigit())
            }
            .foregroundStyle(.white)
            Slider(value: value, in: viewModel.sliderRange).tint(.blue)
        }
    }
}
