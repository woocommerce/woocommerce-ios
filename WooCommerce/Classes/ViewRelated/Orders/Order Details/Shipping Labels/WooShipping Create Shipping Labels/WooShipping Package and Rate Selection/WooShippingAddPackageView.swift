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
    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
    }

    @Environment(\.presentationMode) var presentationMode

    @State var selectedPackageType = PackageProviderType.custom
    @State var packageType: PackageType = .box
    @State var showSaveTemplate: Bool = false
    @State var length: String = ""
    // TODO: add docs
    @State var fieldValues: [WooShippingAddPackageDimensionView.DimensionType: String] = [:]
    @FocusState var focusedField: WooShippingAddPackageDimensionView.DimensionType?
    @State var packageName: String = ""
    @FocusState var packageNameFieldFocused: Bool

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
                selectedPackageTypeView
                Spacer()
                Button(Localization.addPackage) {
                    addPackageButtonTapped()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(addPackageButtonDisabled)
                .padding()
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
    }

    // MARK: UI components

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

    private var customPackageView: some View {
        VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
            HStack {
                Text(Localization.packageType)
                    .font(.subheadline)
                Spacer()
            }
            Menu {
                // show selection
                ForEach(PackageType.allCases, id: \.self) { option in
                    Button {
                        packageType = option
                    } label: {
                        Text(option.name)
                            .bodyStyle()
                        if packageType == option {
                            Image(uiImage: .checkmarkStyledImage)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(packageType.name)
                        .bodyStyle()
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
                .padding()
            }
            .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
            AdaptiveStack(spacing: 8) {
                ForEach(WooShippingAddPackageDimensionView.DimensionType.allCases, id: \.self) { dimensionType in
                    WooShippingAddPackageDimensionView(dimensionType: dimensionType, fieldValue: Binding(get: {
                        return self.fieldValues[dimensionType] ?? ""
                    }, set: { value in
                        self.fieldValues[dimensionType] = value
                    }), focusedField: _focusedField)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Group {
                        Button(action: {
                            onBackwardButtonTapped()
                        }, label: {
                            Image(systemName: "chevron.backward")
                        })
                        .disabled(focusedField == WooShippingAddPackageDimensionView.DimensionType.allCases.first)
                        Button(action: {
                            onForwardButtonTapped()
                        }, label: {
                            Image(systemName: "chevron.forward")
                        })
                        .disabled(focusedField == WooShippingAddPackageDimensionView.DimensionType.allCases.last)
                        Spacer()
                        Button {
                            focusedField = nil
                        } label: {
                            Text(Localization.keyboardDoneButton)
                                .bold()
                        }
                    }
                }
            }
            Toggle(isOn: $showSaveTemplate) {
                Text(Localization.saveNewPackageTemplate)
                    .font(.subheadline)
            }
            .tint(Color(.withColorStudio(.wooCommercePurple, shade: .shade60)))
            if showSaveTemplate {
                TextField("Enter a unique package name", text: $packageName)
                    .font(.body)
                    .focused($packageNameFieldFocused)
                    .padding()
                    .roundedBorder(cornerRadius: 8,
                                   lineColor: packageNameFieldFocused ? Color(UIColor.wooCommercePurple(.shade60)) : Color(.separator),
                                   lineWidth: packageNameFieldFocused ? 2 : 1)
                Button(Localization.savePackageTemplate) {
                    savePackageAsTemplateButtonTapped()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    private func onBackwardButtonTapped() {
        switch focusedField {
        case .length:
            return
        case .width:
            focusedField = .length
        case .height:
            focusedField = .width
        case nil:
            return
        }
    }

    private func onForwardButtonTapped() {
        switch focusedField {
        case .length:
            focusedField = .width
        case .width:
            focusedField = .height
        case .height:
            return
        case nil:
            return
        }
    }

    private var carrierPackageView: some View {
        // TODO: just a placeholder
        Text(Localization.carrier)
    }

    private var savedPackageView: some View {
        // TODO: just a placeholder
        Text(Localization.saved)
    }

    // MARK: - actions

    private func addPackageButtonTapped() {
        // TODO: implement adding a package
    }

    private func savePackageAsTemplateButtonTapped() {
        // TODO: implement saving package as a template
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
    @FocusState var focusedField: WooShippingAddPackageDimensionView.DimensionType?

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
                    .bodyStyle()
                    .focused($focusedField, equals: dimensionType)
                Text("cm")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .roundedBorder(cornerRadius: 8,
                           lineColor: focusedField == dimensionType ? Color(UIColor.wooCommercePurple(.shade60)) : Color(.separator),
                           lineWidth: focusedField == dimensionType ? 2 : 1)
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    WooShippingAddPackageView()
}

extension WooShippingAddPackageView {
    enum Localization {
        static let addPackage = NSLocalizedString("wooShipping.createLabel.addPackage.title",
                                                  value: "Add Package",
                                                  comment: "Title for the Add Package screen")
        static let packageType = NSLocalizedString("wooShipping.createLabel.addPackage.packageType",
                                                   value: "Package type",
                                                   comment: "Info label for selecting package type")
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
        static let box = NSLocalizedString("wooShipping.createLabel.addPackage.box",
                                           value: "Box",
                                           comment: "Info label for selected box as a package type")
        static let envelope = NSLocalizedString("wooShipping.createLabel.addPackage.envelope",
                                                value: "Envelope",
                                                comment: "Info label for selected envelope as a package type")
        static let saveNewPackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.saveNewPackageTemplate",
                                                              value: "Save this as a new package template",
                                                              comment: "Info label for saving package as a new template toggle")
        static let savePackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.savePackageTemplate",
                                                           value: "Save package template",
                                                           comment: "Button for saving package as a new template")
        static let keyboardDoneButton = NSLocalizedString(
            "wooShipping.createLabel.addPackage.keyboard.toolbar.done.button.title",
            value: "Done",
            comment: "The title for a button to dismiss the keyboard on the order creation/editing screen")
    }
}

extension WooShippingAddPackageDimensionView {
    enum Localization {
        static let length = NSLocalizedString("wooShipping.createLabel.addPackage.length",
                                              value: "Length",
                                              comment: "Info label for length input field")
        static let width = NSLocalizedString("wooShipping.createLabel.addPackage.width",
                                             value: "Width",
                                             comment: "Info label for width input field")
        static let height = NSLocalizedString("wooShipping.createLabel.addPackage.height",
                                              value: "Height",
                                              comment: "Info label for height input field")
    }
}
