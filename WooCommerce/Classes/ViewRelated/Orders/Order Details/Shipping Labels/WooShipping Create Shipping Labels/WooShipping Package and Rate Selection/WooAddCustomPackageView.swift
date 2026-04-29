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

    @State private var isSavingPackage = false
    @State private var showingSavingError = false
    @State private var foundInvalidDimensions = false

    @Environment(\.shippingDimensionsUnit) private var dimensionsUnit
    @Environment(\.shippingWeightUnit) private var weightUnit

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
                                    unitInputView(for: dimensionUnit, unit: dimensionsUnit)
                                }
                            }

                            if foundInvalidDimensions {
                                Text(Localization.invalidDimensions)
                                    .font(.footnote)
                                    .foregroundColor(Color(.error))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // showing weight input only if we are saving the template
                            if viewModel.showSaveTemplate {
                                unitInputView(for: WooShippingPackageUnitType.weight, unit: weightUnit)
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
                            Button(selectionButtonText) {
                                confirmPackage()
                            }
                            .disabled(selectionButtonDisabled)
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.bottom)
                        }
                    }
                    .padding(.horizontal)
                    .frame(minHeight: geometry.size.height)
                    .frame(width: geometry.size.width)
                    .onChange(of: viewModel.showSaveTemplate) { _, newValue in
                        packageTemplateNameFieldFocused = newValue
                    }
                    .onChange(of: packageTemplateNameFieldFocused) { _, focused in
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
                .alert(Localization.SavingPackageError.title, isPresented: $showingSavingError, actions: {
                    Button(role: .cancel) {} label: {
                        Text(Localization.SavingPackageError.cancel)
                    }
                    Button {
                        confirmPackage()
                    } label: {
                        Text(Localization.SavingPackageError.proceed)
                    }
                }, message: {
                    Text(Localization.SavingPackageError.message)
                })
            }
        }
    }
}

private extension WooAddCustomPackageView {
    var selectionButtonDisabled: Bool {
        !viewModel.validateCustomPackageInputFields()
    }

    var selectionButtonText: String {
        if selectionButtonDisabled {
            return WooShippingAddPackageView.Localization.addPackageDetails
        }
        return WooShippingAddPackageView.Localization.addPackage
    }

    func unitInputView(for unitType: WooShippingPackageUnitType, unit: String) -> some View {
        WooShippingAddPackageUnitInputView(unitType: unitType,
                                           unit: unit,
                                           fieldValue: Binding(get: {
            return self.viewModel.fieldValues[unitType] ?? ""
        }, set: { value in
            self.viewModel.fieldValues[unitType] = value
        }), focusedField: _focusedField)
    }

    // MARK: - actions

    func confirmPackage() {
        foundInvalidDimensions = !viewModel.allDimensionsValid
        guard !foundInvalidDimensions, let packageData = viewModel.packageData else {
            return
        }
        addPackageAction(packageData)
    }

    @MainActor
    func savePackageAsTemplateButtonTapped() async {
        foundInvalidDimensions = !viewModel.allDimensionsValid
        guard !foundInvalidDimensions else {
            return
        }
        let packageDataResult = await viewModel.savePackageAsTemplateAction()
        // call addPackageAction with data
        switch packageDataResult {
        case .success(let data):
            addPackageAction(data)
        case .failure(let failure):
            DDLogError("⛔️ Error saving package: \(failure)")
            showingSavingError = true
        }
    }

    func onBackwardButtonTapped() {
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

    func onForwardButtonTapped() {
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

    func dismissKeyboard() {
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
        static let invalidDimensions = NSLocalizedString(
            "wooShipping.createLabel.addPackage.invalidDimensions",
            value: "Package dimensions should all be larger than 0",
            comment: "Message when user attempts to confirm a package with invalid dimension in the shipping label creation flow"
        )
        enum SavingPackageError {
            static let title = NSLocalizedString(
                "wooShipping.createLabel.addPackage.savingPackageError.title",
                value: "We couldn't save your package as a template",
                comment: "Title of the error alert when saving a package as template fails in the shipping label creation flow"
            )
            static let message = NSLocalizedString(
                "wooShipping.createLabel.addPackage.savingPackageError.message",
                value: "Do you want to proceed without saving it?",
                comment: "Message of the error alert when saving a package as template fails in the shipping label creation flow"
            )
            static let cancel = NSLocalizedString(
                "wooShipping.createLabel.addPackage.savingPackageError.cancel",
                value: "Cancel",
                comment: "Button on the error alert when saving a package as template fails in the shipping label creation flow. " +
                "Tapping on this button would cancel the saving."
            )
            static let proceed = NSLocalizedString(
                "wooShipping.createLabel.addPackage.savingPackageError.proceed",
                value: "Proceed",
                comment: "Button on the error alert when saving a package as template fails in the shipping label creation flow. " +
                "Tapping on this button would proceed with the creation flow without saving the package."
            )
        }
    }
}
