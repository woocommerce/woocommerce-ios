import SwiftUI

/// View to add/edit a single shipping line in an order, including shipping method selection, with the option to remove it.
///
struct ShippingLineSelectionDetails: View {

    /// View model to drive the view content
    ///
    @StateObject var viewModel: ShippingLineSelectionDetailsViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: Shipping Method
                NavigationLink {
                    SingleSelectionList(title: Localization.methodTitle,
                                        items: viewModel.shippingMethods,
                                        contentKeyPath: \.title,
                                        selected: $viewModel.selectedMethod,
                                        showDoneButton: false,
                                        backgroundColor: nil) { method in
                        viewModel.trackShippingMethodSelected(method)
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(Localization.methodTitle)
                            .font(.title3)
                            .foregroundColor(Color(.textSubtle))
                        Text(viewModel.selectedMethod.title)
                            .font(.title2.bold())
                            .foregroundColor(viewModel.selectedMethodColor)
                    }
                }

                // MARK: Amount
                VStack(alignment: .leading) {
                    Text(Localization.amountTitle)
                        .font(.title3)
                        .foregroundColor(Color(.textSubtle))
                    FormattableAmountTextField(viewModel: viewModel.formattableAmountViewModel)
                }

                // MARK: Name
                VStack(alignment: .leading) {
                    Text(Localization.nameTitle)
                        .font(.title3)
                        .foregroundColor(Color(.textSubtle))
                    TextField(Localization.namePlaceholder, text: $viewModel.methodTitle)
                        .secondaryTitleStyle()
                        .accessibilityIdentifier(Accessibility.nameField)
                }

                // MARK: Delete Shipping Button
                Button(Localization.deleteShippingButton) {
                    viewModel.removeShippingLine()
                    dismiss()
                }
                .foregroundColor(.init(uiColor: .error))
                .buttonStyle(RoundedBorderedStyle(borderColor: .init(uiColor: .error)))
                .renderedIf(viewModel.isExistingShippingLine)
                .listRowSeparator(.hidden, edges: .bottom)
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .bottom, content: {
                // MARK: Add Shipping Button
                Button(Localization.doneButton(isEditing: viewModel.isExistingShippingLine)) {
                    viewModel.saveData()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.enableDoneButton)
                .accessibilityIdentifier(Accessibility.doneButton)
                .padding()
                .background(Color(.systemBackground))
            })
            .navigationTitle(Localization.shipping)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension ShippingLineSelectionDetails {
    enum Localization {
        static let shipping = NSLocalizedString("order.shippingLineDetails.shippingTitle",
                                                value: "Shipping",
                                                comment: "Title for the Shipping Line Details screen during order creation")
        static let cancel = NSLocalizedString("order.shippingLineDetails.cancel",
                                              value: "Cancel",
                                              comment: "Text for the cancel button in the Shipping Line Details screen")

        static let methodTitle = NSLocalizedString("order.shippingLineDetails.method",
                                                 value: "Method",
                                                 comment: "Title above the shipping method field on the Shipping Line Details screen")

        static let amountTitle = NSLocalizedString("order.shippingLineDetails.amount",
                                                 value: "Amount",
                                                 comment: "Title above the amount field on the Shipping Line Details screen")

        static let nameTitle = NSLocalizedString("order.shippingLineDetails.name",
                                                 value: "Name",
                                                 comment: "Title above the name field on the Shipping Line Details screen")
        static let namePlaceholder = NSLocalizedString("order.shippingLineDetails.namePlaceholder",
                                                       value: "Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen")

        static func doneButton(isEditing: Bool) -> String {
            if isEditing {
                return editShippingButton
            } else {
                return addShippingButton
            }
        }
        static let editShippingButton = NSLocalizedString("order.shippingLineDetails.editShipping",
                                                          value: "Edit Shipping",
                                                          comment: "Button to edit a shipping line to the order during order creation")
        static let addShippingButton = NSLocalizedString("order.shippingLineDetails.addShipping",
                                                         value: "Add Shipping",
                                                         comment: "Button to add a shipping line to the order during order creation")
        static let deleteShippingButton = NSLocalizedString("order.shippingLineDetails.removeShipping",
                                                            value: "Remove Shipping from Order",
                                                            comment: "Button to remove a shipping line from the order during order creation")
    }

    enum Accessibility {
        static let nameField = "add-shipping-name-field"
        static let doneButton = "add-shipping-done-button"
    }
}

#Preview("Add shipping") {
    ShippingLineSelectionDetails(viewModel: ShippingLineSelectionDetailsViewModel(siteID: 1,
                                                                                  shippingID: nil,
                                                                                  initialMethodID: "",
                                                                                  initialMethodTitle: "",
                                                                                  shippingTotal: "",
                                                                                  didSelectSave: { _ in },
                                                                                  didSelectRemove: { _ in }))
}

#Preview("Edit shipping") {
    ShippingLineSelectionDetails(viewModel: ShippingLineSelectionDetailsViewModel(siteID: 1,
                                                                                  shippingID: 1,
                                                                                  initialMethodID: "flat_rate",
                                                                                  initialMethodTitle: "Shipping",
                                                                                  shippingTotal: "10.00",
                                                                                  didSelectSave: { _ in },
                                                                                  didSelectRemove: { _ in }))
}
