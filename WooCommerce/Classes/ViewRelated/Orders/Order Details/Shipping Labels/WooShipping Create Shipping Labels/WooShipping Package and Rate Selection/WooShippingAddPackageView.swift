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

    @State var selectedPackageType = PackageProviderType.custom
    var addPackageButtonDisabled: Bool {
        for (_, value) in fieldValues {
            if value.isEmpty {
                return true
            }
        }
        return fieldValues.count != WooShippingAddPackageDimensionView.DimensionType.allCases.count
    }

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
                Spacer()
                selectedPackageTypeView
                Spacer()
                Button(Localization.addPackage) {
                    // add package
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(addPackageButtonDisabled)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
    }

    @ViewBuilder
    private var selectedPackageTypeView: some View {
        ScrollView {
            switch selectedPackageType {
            case .custom:
                customPackageView
            case .carrier:
                carrierPackageView
            case .saved:
                savedPackageView
            }
        }
    }

    enum PackageType: CaseIterable {
        case box, envelope
        var name: String {
            switch self {
            case .box:
                return Localization.box
            case .envelope:
                return Localization.envelope
            }
        }
    }

    @State var packageType: PackageType = .box
    @State var showSaveTemplate: Bool = false
    @State var length: String = ""
    @State var fieldValues: [WooShippingAddPackageDimensionView.DimensionType: String] = [:]

    private var customPackageView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(Localization.packageType)
                    .font(.subheadline)
                Spacer()
            }
            // type selection
            Menu {
                // show selection
                ForEach(PackageType.allCases, id: \.self) { option in
                    Button {
                        packageType = option
                    } label: {
                        Text(option.name)
                            .font(.body)
                    }
                }
            } label: {
                HStack {
                    // text
                    Text(packageType.name)
                    // arrows
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
                .padding()
            }
            .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
            HStack(spacing: 8) {
                ForEach(WooShippingAddPackageDimensionView.DimensionType.allCases, id: \.self) { dimensionType in
                    WooShippingAddPackageDimensionView(dimensionType: dimensionType, fieldValue: Binding(get: {
                        return self.fieldValues[dimensionType] ?? ""
                    }, set: { value in
                        self.fieldValues[dimensionType] = value
                    }))
                }
            }
            Toggle(isOn: $showSaveTemplate) {
                Text(Localization.saveNewPackageTemplate)
                    .font(.subheadline)
            }
            if showSaveTemplate {
                Button(Localization.savePackageTemplate) {
                    // save template
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
    }

    private var carrierPackageView: some View {
        // TODO: just a placeholder
        Text("carrier")
    }

    private var savedPackageView: some View {
        // TODO: just a placeholder
        Text("saved")
    }
}

struct WooShippingAddPackageDimensionView: View {
    enum DimensionType: CaseIterable {
        case length, width, height
        var name: String {
            switch self {
            case .length:
                return Localization.length
            case .width:
                return Localization.width
            case .height:
                return Localization.height
            }
        }
    }

    let dimensionType: DimensionType
    @Binding var fieldValue: String
    @FocusState var fieldFocused: Bool

    var body: some View {
        VStack {
            HStack {
                Text(dimensionType.name)
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                TextField("", text: $fieldValue)
                    .keyboardType(.decimalPad)
                    .font(.body)
                    .focused($fieldFocused)
                Text("cm")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: 8,
                           lineColor: fieldFocused ? Color(UIColor.wooCommercePurple(.shade60)) : Color(.separator),
                           lineWidth: fieldFocused ? 2 : 1)
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    WooShippingAddPackageView()
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("Add Package", comment: "Description")
        static let packageType = NSLocalizedString("Package type", comment: "Description")
        static let cancel = NSLocalizedString("Cancel", comment: "Description")
        static let custom = NSLocalizedString("Custom", comment: "Description")
        static let carrier = NSLocalizedString("Carrier", comment: "Description")
        static let saved = NSLocalizedString("Saved", comment: "Description")
        static let box = NSLocalizedString("Box", comment: "Description")
        static let envelope = NSLocalizedString("Envelope", comment: "Description")
        static let saveNewPackageTemplate = NSLocalizedString("Save this a new package template", comment: "Description")
        static let savePackageTemplate = NSLocalizedString("Save package template", comment: "Description")
    }
}

extension WooShippingAddPackageDimensionView {
    enum Localization {
        static let length = NSLocalizedString("Length", comment: "Description")
        static let width = NSLocalizedString("Width", comment: "Description")
        static let height = NSLocalizedString("Height", comment: "Description")
    }
}
