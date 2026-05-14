import SwiftUI
import ParcelFittingCheck

struct WooShippingSelectedPackageView: View {
    let package: WooShippingPackageDataRepresentable
    @Binding var totalWeight: String

    @Environment(\.shippingWeightUnit) private var weightUnit

    @State private var showPackageSelection = false
    @State private var showARResults = false

    let lastARState: ARSelectionState?
    weak var parcelFittingDelegate: ParcelFittingDelegate?
    let updateSelectedPackage: (WooShippingPackageDataRepresentable) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.package)
                    .headlineStyle()
                Spacer()
                PencilEditButton {
                    if lastARState != nil {
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
                    showPackageSelection = false
                    updateSelectedPackage(newPackage)
                },
                arDelegate: parcelFittingDelegate
            )
        }
        .fullScreenCover(isPresented: $showARResults) {
            if let arState = lastARState {
                NavigationView {
                    ARParcelFittingResultsView(
                        viewModel: ARParcelFittingResultsViewModel(
                            measuredDimensions: arState.measurement,
                            unit: arState.dimensionUnit,
                            carriers: arState.carriers
                        ),
                        starredPackageIDs: arState.starredPackageIDs,
                        delegate: parcelFittingDelegate,
                        onConfirm: { result in
                            showARResults = false
                            parcelFittingDelegate?.parcelFittingDidConfirm(
                                result,
                                carriers: arState.carriers,
                                starredPackageIDs: arState.starredPackageIDs,
                                dimensionUnit: arState.dimensionUnit
                            )
                        },
                        onBrowseAllPackages: {
                            showARResults = false
                            showPackageSelection = true
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(Localization.done) {
                                showARResults = false
                            }
                        }
                    }
                }
                .navigationViewStyle(.stack)
                .tint(Color(.withColorStudio(.wooCommercePurple, shade: .shade60)))
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
                                   lastARState: nil,
                                   updateSelectedPackage: { _ in })
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
                                   lastARState: nil,
                                   updateSelectedPackage: { _ in })
    .shippingDimensionsUnit("in")
    .shippingWeightUnit("lb")
}
