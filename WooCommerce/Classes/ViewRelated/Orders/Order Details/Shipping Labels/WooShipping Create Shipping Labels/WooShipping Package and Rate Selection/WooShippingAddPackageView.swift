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
                Button {
                    // add package
                } label: {
                    Text(Localization.addPackage)
                }

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

    private var customPackageView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Package type")
                Spacer()
            }
            // type selection
            Picker(selection: $packageType) {
                ForEach(PackageType.allCases, id: \.self) {
                    Text($0.name)
                }
            } label: {
                EmptyView()
            }
            HStack {
                ForEach(WooShippingAddPackageDimensionView.DimensionType.allCases, id: \.self) {
                    WooShippingAddPackageDimensionView(dimensionType: $0)
                }
            }
            Toggle(isOn: $showSaveTemplate) {
                Text("Save this a new package template")
            }
            if showSaveTemplate {
                Button {
                    // save template
                } label: {
                    Text("Save package template")
                }

            }
        }
        .padding()
    }

    private var carrierPackageView: some View {
        Text("carrier")
    }

    private var savedPackageView: some View {
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
    @State var fieldValue: String = ""

    var body: some View {
        VStack {
            Text(dimensionType.name)
            TextField(dimensionType.name, text: $fieldValue)
        }
    }
}

#Preview {
    WooShippingAddPackageView()
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("Add Package", comment: "Description")
        static let cancel = NSLocalizedString("Cancel", comment: "Description")
        static let custom = NSLocalizedString("Custom", comment: "Description")
        static let carrier = NSLocalizedString("Carrier", comment: "Description")
        static let saved = NSLocalizedString("Saved", comment: "Description")
        static let box = NSLocalizedString("Box", comment: "Description")
        static let envelope = NSLocalizedString("Envelope", comment: "Description")
    }
}

extension WooShippingAddPackageDimensionView {
    enum Localization {
        static let length = NSLocalizedString("Length", comment: "Description")
        static let width = NSLocalizedString("Width", comment: "Description")
        static let height = NSLocalizedString("Height", comment: "Description")
    }
}
