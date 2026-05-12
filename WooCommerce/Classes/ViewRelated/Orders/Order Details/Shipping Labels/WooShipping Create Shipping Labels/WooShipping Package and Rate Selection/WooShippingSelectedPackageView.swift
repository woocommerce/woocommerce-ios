import SwiftUI
import ParcelFittingCheck

struct WooShippingSelectedPackageView: View {
    let package: WooShippingPackageDataRepresentable
    @Binding var totalWeight: String

    @Environment(\.shippingWeightUnit) private var weightUnit

    @State private var showPackageSelection = false
    @State private var showARResults = false

    let lastARMeasurement: ParcelDimensions?
    weak var parcelFittingDelegate: ParcelFittingDelegate?
    let updateSelectedPackage: (WooShippingPackageDataRepresentable, ParcelDimensions?) -> Void

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
                updateSelectedPackage(newPackage, measurement)
                showPackageSelection = false
            }
        }
        .fullScreenCover(isPresented: $showARResults) {
            ARResultsReEntryView(
                measurement: lastARMeasurement,
                selectedPackage: package,
                delegate: parcelFittingDelegate,
                onConfirm: { packageData, measurement in
                    showARResults = false
                    updateSelectedPackage(packageData, measurement)
                },
                onDismiss: {
                    showARResults = false
                },
                onBrowseAllPackages: {
                    showARResults = false
                    showPackageSelection = true
                }
            )
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
}

private struct ARResultsReEntryView: View {
    let measurement: ParcelDimensions?
    let selectedPackage: WooShippingPackageDataRepresentable
    weak var delegate: ParcelFittingDelegate?
    let onConfirm: (WooShippingPackageDataRepresentable, ParcelDimensions) -> Void
    let onDismiss: () -> Void
    let onBrowseAllPackages: () -> Void

    @State private var packagesVM: WooShippingAddPackageViewModel?

    var body: some View {
        NavigationView {
            Group {
                if let measurement, let packagesVM {
                    ARParcelFittingResultsView(
                        viewModel: ARParcelFittingResultsViewModel(
                            measuredDimensions: measurement,
                            unit: packagesVM.arDimensionUnit,
                            carriers: packagesVM.parcelPresetCarriers
                        ),
                        starredPackageIDs: packagesVM.starredCarriersPackages,
                        delegate: delegate,
                        onConfirm: { result in
                            if let packageData = packagesVM.resolveARResult(result) {
                                onConfirm(packageData, result.measurement)
                            }
                        },
                        onBack: onDismiss,
                        onBrowseAllPackages: onBrowseAllPackages
                    )
                } else {
                    ProgressView()
                }
            }
        }
        .navigationViewStyle(.stack)
        .task {
            let viewModel = WooShippingAddPackageViewModel(selectedPackage: selectedPackage)
            await viewModel.loadPackages()
            packagesVM = viewModel
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
                                   lastARMeasurement: nil,
                                   updateSelectedPackage: { _, _ in })
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
                                   updateSelectedPackage: { _, _ in })
    .shippingDimensionsUnit("in")
    .shippingWeightUnit("lb")
}
