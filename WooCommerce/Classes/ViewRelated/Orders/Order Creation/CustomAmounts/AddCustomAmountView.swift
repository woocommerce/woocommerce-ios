import SwiftUI
import WooFoundation

struct AddCustomAmountView: View {
    @ObservedObject private(set) var viewModel: AddCustomAmountViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let formattableAmountTextFieldViewModel = viewModel.formattableAmountTextFieldViewModel {
                    VStack(alignment: .leading) {
                        Text(Localization.amountTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))
                        FormattableAmountTextField(viewModel: formattableAmountTextFieldViewModel)
                    }
                }

                if let percentageViewModel = viewModel.percentageViewModel {
                    AddCustomAmountPercentageView(viewModel: percentageViewModel)
                }

                Toggle(Localization.chargeTaxesToggleTitle, isOn: $viewModel.isTaxable)
                    .font(.title3)

                VStack(alignment: .leading) {
                    Text(Localization.nameTitle)
                        .font(.title3)
                        .foregroundColor(Color(.textSubtle))
                    TextField(viewModel.customAmountPlaceholder, text: $viewModel.name)
                        .secondaryTitleStyle()
                        .foregroundColor(Color(.textSubtle))
                }

                Button(Localization.deleteButtonTitle) {
                    viewModel.deleteButtonPressed()
                    dismiss()
                }
                .foregroundColor(.init(uiColor: .error))
                .buttonStyle(RoundedBorderedStyle(borderColor: .init(uiColor: .error)))
                .accessibilityIdentifier(AccessibilityIdentifiers.deleteCustomAmountButton)
                .listRowSeparator(.hidden, edges: .bottom)
                .renderedIf(viewModel.shouldShowDeleteButton)
            }
            .listStyle(.plain)
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
    }
}

private extension AddCustomAmountView {
    enum Layout {
        static let mainVerticalSpacing: CGFloat = 8
    }
}

private extension AddCustomAmountView {
    enum Localization {
        static let amountTitle = NSLocalizedString("Amount", comment: "Label text that appears on coupon details screens and custom amount input forms to identify monetary value fields or sections.")
        static let nameTitle = NSLocalizedString("Name", comment: "Title above the name field on the add custom amount view in orders.")
        static let deleteButtonTitle = NSLocalizedString("addCustomAmount.deleteButton",
                                                         value: "Delete Custom Amount",
                                                         comment: "This is a button label that appears on the custom amount editing screen in the order creation flow, allowing users to delete a previously added custom amount from an order.")
        static let navigationTitle = NSLocalizedString("Custom Amount", comment: "Navigation title on the add custom amount view in orders.")
        static let navigationCancelButtonTitle = NSLocalizedString("Cancel",
                                                                   comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
        static let chargeTaxesToggleTitle = NSLocalizedString("addCustomAmountView.chargeTaxesToggle.title",
                                                              value: "Charge Taxes",
                                                              comment: "This is the title text for a toggle switch control that allows users to enable or disable tax charges when adding a custom amount to an order in the WooCommerce app.")
    }

    enum AccessibilityIdentifiers {
        static let addCustomAmountButton = "order-add-custom-amount-view-add-custom-amount-button"
        static let deleteCustomAmountButton = "order-add-custom-amount-view-delete-custom-amount-button"
    }
}
