import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @StateObject private var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: FocusedField?

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
                            fixedAmountField(viewModel: formattableAmountTextFieldViewModel)
                        }
                    }

                    if let percentageViewModel = viewModel.percentageViewModel {
                        AddCustomAmountPercentageView(viewModel: percentageViewModel,
                                                      focusedField: $focusedField)
                    }

                    Toggle(Localization.chargeTaxesToggleTitle, isOn: $viewModel.isTaxable)
                        .font(.title3)
                        .onChange(of: viewModel.isTaxable) {
                            focusedField = nil
                        }

                    VStack(alignment: .leading) {
                        Text(Localization.nameTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))
                        TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                            .secondaryTitleStyle()
                            .foregroundColor(Color(.textSubtle))
                            .focused($focusedField, equals: .name)
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
        .defaultFocus($focusedField, .input)
    }
}

extension AddCustomAmountView {
    enum FocusedField: Hashable {
        case input
        case name
    }
}

private extension AddCustomAmountView {
    func fixedAmountField(viewModel: FormattableAmountTextFieldViewModel) -> some View {
        TextField("", text: fixedAmountText(viewModel), prompt: fixedAmountPlaceholder(viewModel))
            .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .input)
            .font(.system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
            .foregroundColor(Color(viewModel.amountTextColor))
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .frame(maxWidth: .infinity,
                   minHeight: Layout.amountInputHeight(size: viewModel.amountTextSize.fontSize, scale: scale),
                   alignment: .leading)
            .padding(5)
            .if(focusedField == .input, transform: { field in
                field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
            })
            .fixedSize(horizontal: false, vertical: true)
    }

    func fixedAmountText(_ viewModel: FormattableAmountTextFieldViewModel) -> Binding<String> {
        Binding(
            get: {
                viewModel.editableFormattedAmount
            },
            set: { newValue in
                viewModel.updateEditableFormattedAmount(newValue)
            }
        )
    }

    func fixedAmountPlaceholder(_ viewModel: FormattableAmountTextFieldViewModel) -> Text {
        Text(BidirectionalText.isolateLeftToRightNumericRuns(in: viewModel.formattedAmount,
                                                             separators: viewModel.numericTextSeparators))
    }
}

private extension AddCustomAmountView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 24
        static let topPadding: CGFloat = 16

        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }

        static func amountInputHeight(size: CGFloat, scale: CGFloat) -> CGFloat {
            // Matches the field's 5-point vertical padding.
            amountFontSize(size: size, scale: scale) + 10
        }
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
