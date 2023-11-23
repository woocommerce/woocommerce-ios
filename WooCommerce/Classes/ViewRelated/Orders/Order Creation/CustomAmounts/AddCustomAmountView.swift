import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.mainVerticalSpacing) {

                        if let formattableAmountTextFieldViewModel = viewModel.formattableAmountTextFieldViewModel {
                            Group {
                                Text(Localization.amountTitle)
                                    .font(.title3)
                                    .foregroundColor(Color(.textSubtle))

                                FormattableAmountTextField(viewModel: formattableAmountTextFieldViewModel)

                                Divider()
                                    .padding(.bottom, Layout.mainVerticalSpacing)
                            }
                        }

                        if let percentageViewModel = viewModel.percentageViewModel {
                            AddCustomAmountPercentageView(viewModel: percentageViewModel)
                                .padding(.bottom, Layout.mainVerticalSpacing)
                        }

                        Toggle(Localization.chargeTaxesToggleTitle, isOn: $viewModel.isTaxable)
                            .font(.title3)
                            .padding(.bottom, Layout.mainVerticalSpacing)

                        Text(Localization.nameTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))

                        TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                            .secondaryTitleStyle()
                            .foregroundColor(Color(.textSubtle))
                            .padding(.bottom, Layout.mainVerticalSpacing)

                        Button(Localization.deleteButtonTitle) {
                            viewModel.deleteButtonPressed()
                            dismiss()
                        }
                        .foregroundColor(.init(uiColor: .error))
                        .buttonStyle(RoundedBorderedStyle(borderColor: .init(uiColor: .error)))
                        .accessibilityIdentifier(AccessibilityIdentifiers.deleteCustomAmountButton)
                        .renderedIf(viewModel.shouldShowDeleteButton)

                        Spacer()

                        Button(viewModel.doneButtonTitle) {
                            viewModel.doneButtonPressed()
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.shouldEnableDoneButton)
                        .accessibilityIdentifier(AccessibilityIdentifiers.addCustomAmountButton)
                    }
                    .padding()
                    .navigationTitle(Localization.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .frame(minHeight: geometry.size.height)
                    .navigationBarItems(leading: Button(action: {
                        dismiss()
                    }) {
                        Text(Localization.navigationCancelButtonTitle)
                    })
                }
                .frame(width: geometry.size.width)
            }
        }
        .wooNavigationBarStyle()
    }
}



private extension AddCustomAmountView {
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
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
