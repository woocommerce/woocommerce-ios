import SwiftUI

struct WooShippingAddPackageView: View {
    enum PackageProviderType: CaseIterable {
        case custom, carrier, saved
        var name: String {
            switch self {
            case .custom:
                return Localization.custom
            case .carrier:
                return Localization.carrier
            case .saved:
                return Localization.saved
            }
        }
    }

    @Environment(\.presentationMode) var presentationMode

    // Holds type of selected package, it can be `custom`, `carrier` or `saved`
    @State var selectedPackageType = PackageProviderType.custom
    @StateObject var packagesRepository = WooShippingPackagesRepository.shared

    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    // MARK: - UI

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selectedPackageType) {
                    ForEach(PackageProviderType.allCases, id: \.self) {
                        Text($0.name)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                selectedPackageTypeView
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text(Localization.cancel)
                    })
                }
            }
            .navigationTitle(Localization.addPackage)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .task {
            packagesRepository.loadPackages()
        }
    }

    // MARK: UI components

    @ViewBuilder
    private var selectedPackageTypeView: some View {
        switch selectedPackageType {
        case .custom:
            customPackageView
        case .carrier:
            carrierPackageView
        case .saved:
            savedPackageView
        }
    }

    @ViewBuilder
    private var customPackageView: some View {
        WooAddCustomPackageView { packageData in
            addPackageAction(packageData)
        }
    }

    private func carrierTabs() -> [WooShippingCarrierPackages] {
        // TODO: dummy data for UI creation
        let uspsPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 1", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 1",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box")
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 2", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 2",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 21",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
                WooShippingPackageData(name: "Small Flat Rate Box 22",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("USPS Priority Mail Flat Rate Boxes"),
                                      packageType: "box"),
            ])
        ]
        let dhlPackageGroups: [WooPackageGroup] = [
            WooPackageGroup(name: "Flat Rate Boxes 3", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 3",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ]),
            WooPackageGroup(name: "Flat Rate Boxes 4", packages: [
                WooShippingPackageData(name: "Small Flat Rate Box 4",
                                      length: "21.92",
                                      width: "13.67",
                                      height: "4.14",
                                      dimensionsUnit: "cm",
                                      weight: "5",
                                      weightUnit: "kg",
                                      source: .predefined("DHL Express"),
                                      packageType: "box"),
            ])
        ]
        let uspsCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.usps, packageGroups: uspsPackageGroups)
        let dhlCarrier: WooShippingCarrierPackages = WooShippingCarrierPackages(carrier: WooShippingCarrier.dhlExpress, packageGroups: dhlPackageGroups)

        return [uspsCarrier, dhlCarrier]
    }

    @ViewBuilder
    private var carrierPackageView: some View {
        WooCarrierPackagesSelectionView(carrierTabs: carrierTabs()) { packageData in
            addPackageAction(packageData)
        }
    }

    @ViewBuilder
    private var savedPackageView: some View {
        WooSavedPackagesSelectionView(viewModel: WooSavedPackagesSelectionViewModel(packagesRepository: packagesRepository)) { packageData in
            addPackageAction(packageData)
        }
    }
}

struct WooShippingAddPackageUnitInputView: View {
    let unitType: WooShippingPackageUnitType
    let unit: String
    @Binding var fieldValue: String
    @FocusState var focusedField: WooShippingPackageUnitType?

    private var isFocused: Bool {
        return focusedField == unitType
    }

    var body: some View {
        VStack {
            HStack {
                Text(unitType.name)
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                TextField("", text: $fieldValue)
                    .keyboardType(.decimalPad)
                    .bodyStyle()
                    .focused($focusedField, equals: unitType)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: 8,
                           lineColor: isFocused ? Color.accentColor : Color(.separator),
                           lineWidth: isFocused ? 2 : 1)
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    WooShippingAddPackageView { _ in }
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.title",
                                                  value: "Add Package",
                                                  comment: "Title for the Add Package screen")
        static let cancel = NSLocalizedString("wooShipping.createLabel.addPackage.cancel",
                                              value: "Cancel",
                                              comment: "Cancel button in navigation bar to dismiss the screen")
        static let custom = NSLocalizedString("wooShipping.createLabel.addPackage.custom",
                                              value: "Custom",
                                              comment: "Info label for custom package option")
        static let carrier = NSLocalizedString("wooShipping.createLabel.addPackage.carrier",
                                               value: "Carrier",
                                               comment: "Info label for carrier package option")
        static let saved = NSLocalizedString("wooShipping.createLabel.addPackage.saved",
                                             value: "Saved",
                                             comment: "Info label for saved package option")
    }
}
