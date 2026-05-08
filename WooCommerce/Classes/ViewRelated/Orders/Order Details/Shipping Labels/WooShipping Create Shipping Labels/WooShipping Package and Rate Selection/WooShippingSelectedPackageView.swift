import SwiftUI
import ParcelFittingCheck

struct WooShippingSelectedPackageView: View {
    let package: WooShippingPackageDataRepresentable
    @Binding var totalWeight: String

    @Environment(\.shippingWeightUnit) private var weightUnit

    @State private var showPackageSelection = false
    @State private var showARResults = false

    let arContext: ARPackageContext?
    weak var parcelFittingDelegate: ParcelFittingDelegate?
    let updateSelectedPackage: (WooShippingPackageDataRepresentable, ARPackageContext?) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.package)
                    .headlineStyle()
                Spacer()
                PencilEditButton {
                    if arContext != nil {
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
            WooShippingAddPackageView(
                selectedPackage: package,
                addPackageAction: { newPackage in
                    updateSelectedPackage(newPackage, nil)
                    showPackageSelection = false
                },
                onARPackageSelected: { newPackage, context in
                    updateSelectedPackage(newPackage, context)
                    showPackageSelection = false
                }
            )
        }
        .fullScreenCover(isPresented: $showARResults) {
            if let arContext {
                NavigationView {
                    ARParcelFittingResultsView(
                        viewModel: ARParcelFittingResultsViewModel(
                            measuredDimensions: arContext.measurement,
                            unit: arContext.dimensionUnit,
                            carriers: arContext.carriers
                        ),
                        starredPackageIDs: arContext.starredPackageIDs,
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
        let context = arContext
        switch result {
        case .carrierPackage(let pkg, let measurement):
            let carrier = context?.carriers.first { $0.packages.contains { $0.id == pkg.id } }
            let source: WooShippingPackageSource = carrier.map {
                .predefined(sourceTitle: $0.name, sourceID: $0.id)
            } ?? .custom
            let packageData = WooShippingPackageData(
                id: pkg.id,
                name: pkg.name,
                length: String(format: "%.1f", pkg.length),
                width: String(format: "%.1f", pkg.width),
                height: String(format: "%.1f", pkg.height),
                weight: "",
                source: source,
                packageType: "box"
            )
            let newContext = context.map {
                ARPackageContext(
                    measurement: measurement,
                    carriers: $0.carriers,
                    starredPackageIDs: $0.starredPackageIDs,
                    dimensionUnit: $0.dimensionUnit,
                    delegate: $0.delegate
                )
            }
            updateSelectedPackage(packageData, newContext)
        case .customDimensions(let dims):
            let packageData = WooShippingPackageData(
                id: "custom_box",
                name: "",
                length: String(format: "%.1f", dims.length),
                width: String(format: "%.1f", dims.width),
                height: String(format: "%.1f", dims.height),
                weight: "",
                source: .custom,
                packageType: "box"
            )
            let newContext = context.map {
                ARPackageContext(
                    measurement: dims,
                    carriers: $0.carriers,
                    starredPackageIDs: $0.starredPackageIDs,
                    dimensionUnit: $0.dimensionUnit,
                    delegate: $0.delegate
                )
            }
            updateSelectedPackage(packageData, newContext)
        }
    }
}

private extension WooShippingSelectedPackageView {
    enum Constants {
        static let cornerRadius: CGFloat = 8
        static let lineColor = Color(.separator)
        static let lineWidth: CGFloat = 0.5
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
                                   arContext: nil,
                                   updateSelectedPackage: { _, _ in })
    .shippingDimensionsUnit("in")
    .shippingWeightUnit("lb")
}
