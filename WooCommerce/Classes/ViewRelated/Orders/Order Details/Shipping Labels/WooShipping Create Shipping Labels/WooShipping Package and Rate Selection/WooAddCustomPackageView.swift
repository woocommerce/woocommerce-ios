import SwiftUI

struct WooAddCustomPackageView: View {
    enum Constants {
        static let defaultVerticalSpacing: CGFloat = 16.0
        static let saveTemplateContentID: String = "saveTemplateContentID"
        static let scrollToDelay: Double = 0.5
    }

    @ObservedObject private var viewModel: WooShippingAddCustomPackageViewModel

    @FocusState var packageTemplateNameFieldFocused: Bool
    @FocusState var focusedField: WooShippingPackageUnitType?

    @State private var isSavingPackage: Bool = false
    @State private var isAddingPackage: Bool = false

    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    init(viewModel: WooShippingAddCustomPackageViewModel, addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
    }

    private var packageTypeSelectionView: some View {
        Menu {
            // show selection
            ForEach(WooShippingPackageType.allCases, id: \.self) { option in
                Button {
                    viewModel.packageType = option
                } label: {
                    Text(option.name)
                        .bodyStyle()
                    if viewModel.packageType == option {
                        Image(uiImage: .checkmarkStyledImage)
                    }
                }
            }
        } label: {
            HStack {
                Text(viewModel.packageType.name)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding()
        }
        .roundedBorder(cornerRadius: 8, lineColor: Color(.separator), lineWidth: 1)
    }

    var body: some View {
        GeometryReader { geometry in
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
                                    unitInputView(for: dimensionUnit, unit: viewModel.dimensionsUnit)
                                }
                            }
                            // showing weight input only if we are saving the template
                            if viewModel.showSaveTemplate {
                                unitInputView(for: WooShippingPackageUnitType.weight, unit: viewModel.weightUnit)
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
                        Toggle(isOn: $viewModel.showSaveTemplate) {
                            Text(Localization.saveNewPackageTemplate)
                                .font(.subheadline)
                        }
                        .tint(Color.accentColor)
                        if viewModel.showSaveTemplate {
                            VStack {
                                TextField(Localization.savePackageTemplatePlaceholder, text: $viewModel.packageTemplateName)
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
                                .disabled(!viewModel.validateCustomPackageInputFields())
                                .buttonStyle(SecondaryLoadingButtonStyle(isLoading: isSavingPackage))
                                .padding(.bottom)
                            }
                            .id(Constants.saveTemplateContentID) // Set the id for the button so we can scroll to it
                        }
                        else {
                            Spacer()
                            Button(WooShippingAddPackageView.Localization.addPackage) {
                                Task { @MainActor in
                                    isAddingPackage = true
                                    await addPackageButtonTapped()
                                    isAddingPackage = false
                                }
                            }
                            .disabled(!viewModel.validateCustomPackageInputFields())
                            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isAddingPackage))
                            .padding(.bottom)
                        }
                    }
                    .padding(.horizontal)
                    .frame(minHeight: geometry.size.height)
                    .frame(width: geometry.size.width)
                    .onChange(of: viewModel.showSaveTemplate) { newValue in
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
    }

    private func unitInputView(for unitType: WooShippingPackageUnitType, unit: String) -> some View {
        WooShippingAddPackageUnitInputView(unitType: unitType,
                                           unit: unit,
                                           fieldValue: Binding(get: {
            return self.viewModel.fieldValues[unitType] ?? ""
        }, set: { value in
            self.viewModel.fieldValues[unitType] = value
        }), focusedField: _focusedField)
    }

    // MARK: - actions

    @MainActor
    private func addPackageButtonTapped() async {
        let packageDataResult = await viewModel.addPackageAction()
        // call addPackageAction with data
        switch packageDataResult {
        case .success(let data):
            addPackageAction(data)
        case .failure(let failure):
            // show failure
            print(failure)
        }
    }

    @MainActor
    private func savePackageAsTemplateButtonTapped() async {
        let packageDataResult = await viewModel.savePackageAsTemplateAction()
        // call addPackageAction with data
        switch packageDataResult {
        case .success(let data):
            addPackageAction(data)
        case .failure(let failure):
            // show failure
            print(failure)
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
