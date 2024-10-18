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

    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
        static let saveTemplateButtonID: String = "saveTemplateButtonID"
        static let scrollToDelay: Double = 0.5
    }

    @Environment(\.presentationMode) var presentationMode

    @StateObject private var customPackageViewModel = WooShippingAddCustomPackageViewModel()
    // Holds type of selected package, it can be `custom`, `carrier` or `saved`
    @State var selectedPackageType = PackageProviderType.custom

    @FocusState var packageTemplateNameFieldFocused: Bool
    @FocusState var focusedField: WooShippingPackageDimensionType?

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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                    HStack {
                        Text(Localization.packageType)
                            .font(.subheadline)
                        Spacer()
                    }
                    Menu {
                        // show selection
                        ForEach(WooShippingPackageType.allCases, id: \.self) { option in
                            Button {
                                customPackageViewModel.packageType = option
                            } label: {
                                Text(option.name)
                                    .bodyStyle()
                                if customPackageViewModel.packageType == option {
                                    Image(uiImage: .checkmarkStyledImage)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(customPackageViewModel.packageType.name)
                                .bodyStyle()
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .padding()
                    }
                    .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
                    AdaptiveStack(spacing: 8) {
                        ForEach(WooShippingPackageDimensionType.allCases, id: \.self) { dimensionType in
                            WooShippingAddPackageDimensionView(dimensionType: dimensionType, fieldValue: Binding(get: {
                                return self.customPackageViewModel.fieldValues[dimensionType] ?? ""
                            }, set: { value in
                                self.customPackageViewModel.fieldValues[dimensionType] = value
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
                                .disabled(focusedField == WooShippingPackageDimensionType.allCases.first)
                                Button(action: {
                                    onForwardButtonTapped()
                                }, label: {
                                    Image(systemName: "chevron.forward")
                                })
                                .disabled(focusedField == WooShippingPackageDimensionType.allCases.last)
                                Spacer()
                                Button {
                                    dismissKeyboard()
                                } label: {
                                    Text(Localization.keyboardDoneButton)
                                        .bold()
                                }
                            }
                            .renderedIf(focusedField != nil)
                        }
                    }
                    Toggle(isOn: $customPackageViewModel.showSaveTemplate) {
                        Text(Localization.saveNewPackageTemplate)
                            .font(.subheadline)
                    }
                    .tint(Color.accentColor)
                    if customPackageViewModel.showSaveTemplate {
                        TextField("Enter a unique package name", text: $customPackageViewModel.packageTemplateName)
                            .font(.body)
                            .focused($packageTemplateNameFieldFocused)
                            .padding()
                            .roundedBorder(cornerRadius: 8,
                                           lineColor: packageTemplateNameFieldFocused ? Color.accentColor : Color(.separator),
                                           lineWidth: packageTemplateNameFieldFocused ? 2 : 1)
                        Button(Localization.savePackageTemplate) {
                            savePackageAsTemplateButtonTapped()
                        }
                        .disabled(!validateCustomPackageInputFields())
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.bottom)
                        .id(Constants.saveTemplateButtonID) // Set the id for the button so we can scroll to it
                    }
                }
                .padding(.horizontal)
                .onChange(of: customPackageViewModel.showSaveTemplate) { newValue in
                    packageTemplateNameFieldFocused = newValue
                }
                .onChange(of: packageTemplateNameFieldFocused) { focused in
                    if focused {
                        // More info about why small delay is added:
                        // - https://github.com/woocommerce/woocommerce-ios/pull/14086#discussion_r1806036901
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scrollToDelay, execute: {
                            withAnimation {
                                proxy.scrollTo(Constants.saveTemplateButtonID, anchor: .bottom)
                            }
                        })
                    }
                }
            }
        }
        if !customPackageViewModel.showSaveTemplate {
            Spacer()
            Button(Localization.addPackage) {
                addPackageButtonTapped()
            }
            .disabled(!validateCustomPackageInputFields())
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
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

    private func dismissKeyboard() {
        focusedField = nil
        packageTemplateNameFieldFocused = false
    }

    @ViewBuilder
    private var carrierPackageView: some View {
        // TODO: just a placeholder
        Spacer()
    }

    @ViewBuilder
    private var savedPackageView: some View {
        // TODO: just a placeholder
        Spacer()
    }

    // MARK: - actions

    private func validateCustomPackageInputFields() -> Bool {
        guard !customPackageViewModel.areFieldValuesInvalid else {
            return false
        }
        if customPackageViewModel.showSaveTemplate {
            return !customPackageViewModel.packageTemplateName.isEmpty
        }
        return true
    }

    private func addPackageButtonTapped() {
        // TODO: implement adding a package
        guard validateCustomPackageInputFields() else { return }
    }

    private func savePackageAsTemplateButtonTapped() {
        // TODO: implement saving package as a template
        guard validateCustomPackageInputFields() else { return }
    }
}

struct WooShippingAddPackageDimensionView: View {
    let dimensionType: WooShippingPackageDimensionType
    @Binding var fieldValue: String
    @FocusState var focusedField: WooShippingPackageDimensionType?

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
                           lineColor: focusedField == dimensionType ? Color.accentColor : Color(.separator),
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
