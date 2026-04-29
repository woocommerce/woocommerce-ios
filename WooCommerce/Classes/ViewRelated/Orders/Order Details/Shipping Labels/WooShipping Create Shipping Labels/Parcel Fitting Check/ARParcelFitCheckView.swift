import SwiftUI

// MARK: - Local models (no WooShipping dependency)

/// A carrier with a flat list of package presets. Mapped from WooShipping
/// types at the call site — the AR view itself knows nothing about the
/// shipping label domain.
struct ParcelPresetCarrier: Identifiable {
    let id: String
    let name: String
    let packages: [ParcelPresetPackage]
}

struct ParcelPresetPackage: Identifiable {
    let id: String
    let name: String
    let length: String
    let width: String
    let height: String
}

// MARK: - View

/// Carrier-flow AR view: drop a wireframe cuboid sized to a chosen carrier
/// package preset, drag and rotate it over the real parcel to see whether it
/// fits. Two `Picker`s let the user swap carrier and package without
/// dismissing the AR view.
///
/// The cuboid itself isn't resizable in this flow — its dimensions are
/// driven by whichever carrier package is currently selected.
struct ARParcelFitCheckView: View {
    let availableCarriers: [ParcelPresetCarrier]
    private let onCancel: () -> Void
    private let onConfirm: (ParcelPresetPackage) -> Void

    @Environment(\.shippingDimensionsUnit) private var dimensionsUnit

    @State private var selectedCarrierID: String?
    @State private var selectedPackageID: String?

    @State private var isPlaced: Bool = false
    @State private var resetTrigger: Int = 0

    init(availableCarriers: [ParcelPresetCarrier],
         initialPackageID: String? = nil,
         onCancel: @escaping () -> Void,
         onConfirm: @escaping (ParcelPresetPackage) -> Void) {
        self.availableCarriers = availableCarriers
        self.onCancel = onCancel
        self.onConfirm = onConfirm

        let initialCarrier = availableCarriers.first { carrier in
            carrier.packages.contains(where: { $0.id == initialPackageID })
        } ?? availableCarriers.first

        self._selectedCarrierID = State(initialValue: initialCarrier?.id)
        self._selectedPackageID = State(
            initialValue: initialPackageID ?? initialCarrier?.packages.first?.id
        )
    }

    var body: some View {
        ZStack {
            ARParcelSceneView(
                dimensions: dimensionsInMeters,
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
                ARCuboidCircleIconButton(systemName: "trash") {
                    resetTrigger += 1
                }
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

                if let package = currentPackage {
                    Text("\(package.length) × \(package.width) × \(package.height) \(unit)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white)
                }

                Button {
                    if let package = currentPackage {
                        onConfirm(package)
                    }
                } label: {
                    Text("Use this package")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.black)
                }
                .disabled(currentPackage == nil)
            }
            .padding(16)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
    }

    private var pickers: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Carrier")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Picker("Carrier", selection: $selectedCarrierID) {
                    ForEach(availableCarriers) { carrier in
                        Text(carrier.name).tag(Optional(carrier.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
                .onChange(of: selectedCarrierID) { _, _ in
                    selectedPackageID = currentCarrierPackages.first?.id
                }
            }

            HStack {
                Text("Package")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Picker("Package", selection: $selectedPackageID) {
                    ForEach(currentCarrierPackages) { package in
                        Text(package.name).tag(Optional(package.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
            }
        }
    }

    // MARK: - Selection helpers

    private var currentCarrier: ParcelPresetCarrier? {
        availableCarriers.first { $0.id == selectedCarrierID }
    }

    private var currentCarrierPackages: [ParcelPresetPackage] {
        currentCarrier?.packages ?? []
    }

    private var currentPackage: ParcelPresetPackage? {
        currentCarrierPackages.first { $0.id == selectedPackageID }
    }

    private var unit: String {
        dimensionsUnit.isEmpty ? "in" : dimensionsUnit
    }

    private var dimensionsInMeters: SIMD3<Float> {
        let factor = DimensionUnitConversion.metersPerUnit(unit)
        let defaults = DimensionUnitConversion.defaultDimensions(for: unit)
        guard let package = currentPackage else {
            return SIMD3(defaults.length * factor,
                         defaults.height * factor,
                         defaults.width * factor)
        }
        let l = (Float(package.length) ?? defaults.length) * factor
        let w = (Float(package.width) ?? defaults.width) * factor
        let h = (Float(package.height) ?? defaults.height) * factor
        return SIMD3(l, h, w)
    }
}
