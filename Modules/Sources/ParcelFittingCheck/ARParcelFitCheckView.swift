import SwiftUI

struct ARParcelFitCheckView: View {
    private let onCancel: () -> Void
    private let onConfirm: (ParcelPresetPackage) -> Void

    @State private var viewModel: ARParcelFitCheckViewModel
    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(unit: UnitLength,
         availableCarriers: [ParcelPresetCarrier],
         initialPackageID: String? = nil,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (ParcelPresetPackage) -> Void) {
        self._viewModel = State(initialValue: ARParcelFitCheckViewModel(
            unit: unit,
            availableCarriers: availableCarriers,
            initialPackageID: initialPackageID
        ))
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
            VStack(spacing: 12) {
                pickers

                if let label = viewModel.dimensionsLabel {
                    Text(label).font(.subheadline.monospacedDigit()).foregroundStyle(.white)
                }

                Button {
                    if let package = viewModel.currentPackage { onConfirm(package) }
                } label: {
                    Text("Use this package")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.black)
                }
                .disabled(viewModel.currentPackage == nil)
            }
            .padding(16)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private var pickers: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Carrier").font(.subheadline).foregroundStyle(.white)
                Spacer()
                Picker("Carrier", selection: $viewModel.selectedCarrierID) {
                    ForEach(viewModel.availableCarriers) { carrier in
                        Text(carrier.name).tag(Optional(carrier.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
                .onChange(of: viewModel.selectedCarrierID) { _, newID in
                    viewModel.selectCarrier(newID)
                }
            }

            HStack {
                Text("Package").font(.subheadline).foregroundStyle(.white)
                Spacer()
                Picker("Package", selection: $viewModel.selectedPackageID) {
                    ForEach(viewModel.currentCarrierPackages) { package in
                        Text(package.name).tag(Optional(package.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
            }
        }
    }
}
