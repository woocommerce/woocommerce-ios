import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @StateObject private var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: AddCustomAmountViewModel.FocusedField?
    @FocusState private var inputFieldIsFocused: Bool

    init(viewModel: AddCustomAmountViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                    if let formattableAmountTextFieldViewModel = viewModel.formattableAmountTextFieldViewModel {
                        VStack(alignment: .leading) {
                            Text(Localization.amountTitle)
                                .font(.title3)
                                .foregroundColor(Color(.textSubtle))
                            FormattableAmountTextField(viewModel: formattableAmountTextFieldViewModel,
                                                       isFocused: inputFocusBinding,
                                                       fieldFocus: $inputFieldIsFocused)
                        }
                    }

                    if let percentageViewModel = viewModel.percentageViewModel {
                        AddCustomAmountPercentageView(viewModel: percentageViewModel,
                                                      isFocused: inputFocusBinding,
                                                      fieldFocus: $inputFieldIsFocused)
                    }

                    Toggle(Localization.chargeTaxesToggleTitle, isOn: $viewModel.isTaxable)
                        .font(.title3)
                        .onChange(of: viewModel.isTaxable) {
                            focusedField = nil
                            viewModel.clearFocus()
                        }

                    VStack(alignment: .leading) {
                        Text(Localization.nameTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))
                        TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                            .secondaryTitleStyle()
                            .foregroundColor(Color(.textSubtle))
                            .focused($focusedField, equals: .name)
                            .onChange(of: focusedField) { _, focusedField in
                                guard focusedField == .name else { return }
                                inputFieldIsFocused = false
                                viewModel.focusName()
                            }
                    }

                    Button(Localization.deleteButtonTitle) {
                        viewModel.deleteButtonPressed()
                        dismiss()
                    }
                    .foregroundColor(.init(uiColor: .error))
                    .buttonStyle(RoundedBorderedStyle(borderColor: .init(uiColor: .error)))
                    .accessibilityIdentifier(AccessibilityIdentifiers.deleteCustomAmountButton)
                    .renderedIf(viewModel.shouldShowDeleteButton)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, Layout.topPadding)
            }
            .safeAreaInset(edge: .bottom) {
                Button(viewModel.doneButtonTitle) {
                    viewModel.doneButtonPressed()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.shouldEnableDoneButton)
                .accessibilityIdentifier(AccessibilityIdentifiers.addCustomAmountButton)
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(Localization.navigationCancelButtonTitle)
                    }
                }
            }
        }
        .wooNavigationBarStyle()
        .onAppear(perform: syncFocusFromViewModel)
        .onChange(of: viewModel.focusedField) { _, focusedField in
            switch focusedField {
            case .input:
                guard inputFieldIsFocused == false else { return }
                inputFieldIsFocused = true
                self.focusedField = nil
            case .name:
                guard self.focusedField != focusedField else { return }
                inputFieldIsFocused = false
                self.focusedField = focusedField
            case nil:
                inputFieldIsFocused = false
                self.focusedField = nil
            }
        }
    }
}

private extension AddCustomAmountView {
    var inputFocusBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.focusedField == .input
            },
            set: { isFocused in
                if isFocused {
                    focusedField = nil
                    inputFieldIsFocused = true
                    viewModel.focusInput()
                } else {
                    inputFieldIsFocused = false
                    viewModel.clearInputFocus()
                }
            }
        )
    }

    func syncFocusFromViewModel() {
        switch viewModel.focusedField {
        case .input:
            inputFieldIsFocused = true
            focusedField = nil
        case .name:
            inputFieldIsFocused = false
            focusedField = viewModel.focusedField
        case nil:
            inputFieldIsFocused = false
            focusedField = nil
        }
    }
}

private extension AddCustomAmountView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 24
        static let topPadding: CGFloat = 16
    }
}

private extension AddCustomAmountView {
    enum Localization {
        static let amountTitle = NSLocalizedString("Amount", comment: "Title above the amount field on the add custom amount view in orders.")
        static let nameTitle = NSLocalizedString("Name", comment: "Title above the name field on the add custom amount view in orders.")
        static let deleteButtonTitle = NSLocalizedString("addCustomAmount.deleteButton",
                                                         value: "Delete Custom Amount",
                                                         comment: "Button title to delete the custom amount on the edit custom amount view in orders.")
        static let navigationTitle = NSLocalizedString("Custom Amount", comment: "Navigation title on the add custom amount view in orders.")
        static let navigationCancelButtonTitle = NSLocalizedString("Cancel",
                                                                   comment: "Cancel button title on the navigation bar on the add custom amount view in orders.")
        static let chargeTaxesToggleTitle = NSLocalizedString("addCustomAmountView.chargeTaxesToggle.title",
                                                              value: "Charge Taxes",
                                                              comment: "Title for the charge taxes toggle in the custom amounts screen.")
    }

    enum AccessibilityIdentifiers {
        static let addCustomAmountButton = "order-add-custom-amount-view-add-custom-amount-button"
        static let deleteCustomAmountButton = "order-add-custom-amount-view-delete-custom-amount-button"
    }
}
