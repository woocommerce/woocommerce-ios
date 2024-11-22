import SwiftUI
import enum Yosemite.WooShippingAction

struct WooAddCustomPackageView: View {
    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
        static let saveTemplateContentID: String = "saveTemplateContentID"
        static let scrollToDelay: Double = 0.5
    }

    @StateObject private var customPackageViewModel = WooShippingAddCustomPackageViewModel()

    @FocusState var packageTemplateNameFieldFocused: Bool
    @FocusState var focusedField: WooShippingPackageUnitType?

    @State private var isSavingPackage: Bool = false

    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    private var packageTypeSelectionView: some View {
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
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if customPackageViewModel.isLoadingStoreOptions {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
                else {
                    Button {
                        customPackageViewModel.loadStoreOptions()
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                    }
                }
                Spacer()
            }
            Spacer()
        }
    }

    var body: some View {
        GeometryReader { geometry in
            if let storeOptions = customPackageViewModel.storeOptions {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Constants.defaultVerticalSpacing) {
                            HStack {
                                Text(Localization.packageType)
                                    .font(.subheadline)
                                Spacer()
                            }
                            packageTypeSelectionView
                            VStack {
                                AdaptiveStack(spacing: 8) {
                                    ForEach(WooShippingPackageUnitType.dimensionUnits, id: \.self) { dimensionUnit in
                                        unitInputView(for: dimensionUnit, unit: storeOptions.dimensionUnit)
                                    }
                                }
                                // showing weight input only if we are saving the template
                                if customPackageViewModel.showSaveTemplate {
                                    unitInputView(for: WooShippingPackageUnitType.weight, unit: storeOptions.weightUnit)
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
                                        .disabled(focusedField == WooShippingPackageUnitType.allCases.first)
                                        Button(action: {
                                            onForwardButtonTapped()
                                        }, label: {
                                            Image(systemName: "chevron.forward")
                                        })
                                        .disabled(focusedField == WooShippingPackageUnitType.allCases.last)
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
                                VStack {
                                    TextField(Localization.savePackageTemplatePlaceholder, text: $customPackageViewModel.packageTemplateName)
                                        .font(.body)
                                        .focused($packageTemplateNameFieldFocused)
                                        .padding()
                                        .roundedBorder(cornerRadius: 8,
                                                       lineColor: packageTemplateNameFieldFocused ? Color.accentColor : Color(.separator),
                                                       lineWidth: packageTemplateNameFieldFocused ? 2 : 1)
                                    Spacer()
                                    Button(Localization.savePackageTemplate) {
                                        Task { @MainActor in
                                            isSavingPackage = true
                                            await savePackageAsTemplateButtonTapped()
                                            isSavingPackage = false
                                        }
                                    }
                                    .disabled(!customPackageViewModel.validateCustomPackageInputFields())
                                    .buttonStyle(SecondaryLoadingButtonStyle(isLoading: isSavingPackage))
                                    .padding(.bottom)
                                }
                                .id(Constants.saveTemplateContentID) // Set the id for the button so we can scroll to it
                            }
                            else {
                                Spacer()
                                Button(WooShippingAddPackageView.Localization.addPackage) {
                                    addPackageButtonTapped()
                                }
                                .disabled(!customPackageViewModel.validateCustomPackageInputFields())
                                .buttonStyle(PrimaryButtonStyle())
                                .padding(.bottom)
                            }
                        }
                        .padding(.horizontal)
                        .frame(minHeight: geometry.size.height)
                        .frame(width: geometry.size.width)
                        .onChange(of: customPackageViewModel.showSaveTemplate) { newValue in
                            packageTemplateNameFieldFocused = newValue
                        }
                        .onChange(of: packageTemplateNameFieldFocused) { focused in
                            if focused {
                                // More info about why small delay is added:
                                // - https://github.com/woocommerce/woocommerce-ios/pull/14086#discussion_r1806036901
                                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scrollToDelay, execute: {
                                    withAnimation {
                                        proxy.scrollTo(Constants.saveTemplateContentID, anchor: .top)
                                    }
                                })
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .disabled(isSavingPackage)
                }
            }
            else {
                loadingView
            }
        }
        .task {
            customPackageViewModel.loadStoreOptions()
        }
    }

    private func unitInputView(for unitType: WooShippingPackageUnitType, unit: String) -> some View {
        WooShippingAddPackageUnitInputView(unitType: unitType,
                                           unit: unit,
                                           fieldValue: Binding(get: {
            return self.customPackageViewModel.fieldValues[unitType] ?? ""
        }, set: { value in
            self.customPackageViewModel.fieldValues[unitType] = value
        }), focusedField: _focusedField)
    }

    // MARK: - actions

    private func addPackageButtonTapped() {
        if let packageData = customPackageViewModel.addPackageAction() {
            // call addPackageAction with data
            addPackageAction(packageData)
        }
    }

    @MainActor
    private func savePackageAsTemplateButtonTapped() async {
        if let packageData = await customPackageViewModel.savePackageAsTemplateAction() {
            // call addPackageAction with data
            addPackageAction(packageData)
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
        case .weight:
            focusedField = .height
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
            focusedField = .weight
        case .weight:
            return
        case nil:
            return
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        packageTemplateNameFieldFocused = false
    }
}

extension WooAddCustomPackageView {
    enum Localization {
        static let packageType = NSLocalizedString("wooShipping.createLabel.addPackage.packageType",
                                                   value: "Package type",
                                                   comment: "Info label for selecting package type")
        static let keyboardDoneButton = NSLocalizedString("wooShipping.createLabel.addPackage.keyboard.toolbar.done.button.title",
                                                          value: "Done",
                                                          comment: "The title for a button to dismiss the keyboard on the order creation/editing screen")
        static let saveNewPackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.saveNewPackageTemplate",
                                                              value: "Save this as a new package template",
                                                              comment: "Info label for saving package as a new template toggle")
        static let savePackageTemplate = NSLocalizedString("wooShipping.createLabel.addPackage.savePackageTemplate",
                                                           value: "Save package template",
                                                           comment: "Button for saving package as a new template")
        static let savePackageTemplatePlaceholder = NSLocalizedString("wooShipping.createLabel.addPackage.savePackageTemplatePlaceholder",
                                                           value: "Enter a unique package name",
                                                           comment: "Placeholder text for package name field")
    }
}
