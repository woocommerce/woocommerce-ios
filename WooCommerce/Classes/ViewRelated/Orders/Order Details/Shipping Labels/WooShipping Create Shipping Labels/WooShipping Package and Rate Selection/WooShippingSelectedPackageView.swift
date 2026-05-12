import SwiftUI
import ParcelFittingCheck

struct WooShippingSelectedPackageView: View {
    let package: WooShippingPackageDataRepresentable
    @Binding var totalWeight: String

    @Environment(\.shippingWeightUnit) private var weightUnit

    @State private var showPackageSelection = false
    @State private var showARResults = false

    let lastARMeasurement: ParcelDimensions?
    let lastARCarriers: [ParcelPresetCarrier]
    let lastARStarredPackageIDs: Set<String>
    let lastARDimensionUnit: UnitLength
    weak var parcelFittingDelegate: ParcelFittingDelegate?
    let updateSelectedPackage: (WooShippingPackageDataRepresentable,
                                ParcelDimensions?,
                                [ParcelPresetCarrier],
                                Set<String>,
                                UnitLength) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.package)
                    .headlineStyle()
                Spacer()
                PencilEditButton {
                    if lastARMeasurement != nil {
                        showARResults = true
                    } else {
                        showPackageSelection = true
                    }
                }
                .buttonStyle(TextButtonStyle())
            }
            WooShippingPackageOptionView(package: package,
                                         showTopDivider: false,
                                         showSource: true,
                                         tapAction: {})
            .roundedBorder(cornerRadius: Constants.cornerRadius, lineColor: Constants.lineColor, lineWidth: Constants.lineWidth)
            .padding(.bottom)
            shipmentWeight
        }
        .sheet(isPresented: $showPackageSelection) {
            WooShippingAddPackageView(selectedPackage: package) { newPackage, measurement in
                showPackageSelection = false
                updateSelectedPackage(newPackage, measurement, lastARCarriers, lastARStarredPackageIDs, lastARDimensionUnit)
            }
        }
        .fullScreenCover(isPresented: $showARResults) {
            if let measurement = lastARMeasurement {
                NavigationView {
                    ARParcelFittingResultsView(
                        viewModel: ARParcelFittingResultsViewModel(
                            measuredDimensions: measurement,
                            unit: lastARDimensionUnit,
                            carriers: lastARCarriers
                        ),
                        starredPackageIDs: lastARStarredPackageIDs,
                        delegate: parcelFittingDelegate,
                        onConfirm: { result in
                            showARResults = false
                            handleARResult(result)
                        },
                        onBack: {
                            showARResults = false
                        },
                        onBrowseAllPackages: {
                            showARResults = false
                            showPackageSelection = true
                        }
                    )
                }
                .navigationViewStyle(.stack)
            }
        }
    }

    @FocusState var isTotalWeightInputActive: Bool

    private var shipmentWeight: some View {
        VStack(alignment: .leading) {
            Text(Localization.totalWeight)
                .bodyStyle()
            HStack {
                TextField("", text: $totalWeight)
                    .keyboardType(.decimalPad)
                    .bodyStyle()
                    .focused($isTotalWeightInputActive)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button {
                                isTotalWeightInputActive = false
                            } label: {
                                Text(Localization.done)
                                    .bold()
                            }
                        }
                    }
                Text(weightUnit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: Constants.cornerRadius, lineColor: Constants.lineColor, lineWidth: Constants.lineWidth)
        }
    }

    private func handleARResult(_ result: ParcelFittingResult) {
        let measurement = result.measurement
        switch result {
        case .carrierPackage(let pkg, _):
            let carrier = lastARCarriers.first { $0.packages.contains { $0.id == pkg.id } }
            let source: WooShippingPackageSource = carrier.map {
                .predefined(sourceTitle: $0.name, sourceID: $0.id)
            } ?? .custom
            let packageData = WooShippingPackageData(
                id: pkg.id,
                name: pkg.name,
                length: ParcelDimensions.formatValue(pkg.length),
                width: ParcelDimensions.formatValue(pkg.width),
                height: ParcelDimensions.formatValue(pkg.height),
                weight: "",
                source: source,
                packageType: "box"
            )
            updateSelectedPackage(packageData, measurement, lastARCarriers, lastARStarredPackageIDs, lastARDimensionUnit)
        case .customDimensions(let dims):
            let packageData = WooShippingPackageData(
                id: Constants.defaultCustomBoxID,
                name: "",
                length: ParcelDimensions.formatValue(dims.length),
                width: ParcelDimensions.formatValue(dims.width),
                height: ParcelDimensions.formatValue(dims.height),
                weight: "",
                source: .custom,
                packageType: "box"
            )
            updateSelectedPackage(packageData, measurement, lastARCarriers, lastARStarredPackageIDs, lastARDimensionUnit)
        }
    }
}

private extension WooShippingSelectedPackageView {
    enum Constants {
        static let cornerRadius: CGFloat = 8
        static let lineColor = Color(.separator)
        static let lineWidth: CGFloat = 0.5
        static let defaultCustomBoxID = "custom_box"
    }

    enum Localization {
        static let package = NSLocalizedString("wooShipping.createLabels.package.title",
                                               value: "Package",
                                               comment: "Heading for the package section in the shipping label creation screen.")
        static let totalWeight = NSLocalizedString("wooShipping.createLabels.package.totalWeight",
                                                    value: "Total shipment weight (with package)",
                                                    comment: "Label for the total shipment weight input field in the shipping label creation screen.")
        static let done = NSLocalizedString("wooShipping.createLabels.package.done",
                                            value: "Done",
                                            comment: "Button for dismissing the keyboard")
    }
}

#Preview("Carrier package") {
    WooShippingSelectedPackageView(package: WooShippingPackageData(name: "Small Flat Rate Box",
                                                                   length: "12",
                                                                   width: "6",
                                                                   height: "6",
                                                                   weight: "4",
                                                                   source: .predefined(sourceTitle: "USPS Priority Mail Flat Rate Boxes", sourceID: "usps"),
                                                                   packageType: "box"),
                                   totalWeight: .constant("6"),
                                   lastARMeasurement: nil,
                                   lastARCarriers: [],
                                   lastARStarredPackageIDs: [],
                                   lastARDimensionUnit: .centimeters,
                                   updateSelectedPackage: { _, _, _, _, _ in })
    .shippingDimensionsUnit("in")
    .shippingWeightUnit("lb")
}

#Preview("Unsaved custom package") {
    WooShippingSelectedPackageView(package: WooShippingPackageData(name: "",
                                                                   length: "12",
                                                                   width: "6",
                                                                   height: "6",
                                                                   weight: "",
                                                                   source: .custom,
                                                                   packageType: "box"),
                                   totalWeight: .constant("6"),
                                   lastARMeasurement: nil,
                                   lastARCarriers: [],
                                   lastARStarredPackageIDs: [],
                                   lastARDimensionUnit: .centimeters,
                                   updateSelectedPackage: { _, _, _, _, _ in })
    .shippingDimensionsUnit("in")
    .shippingWeightUnit("lb")
}
