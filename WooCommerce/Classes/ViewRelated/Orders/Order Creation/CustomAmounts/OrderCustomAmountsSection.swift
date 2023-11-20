import SwiftUI

struct OrderCustomAmountsSection: View {
    enum ConfirmationOption {
        case fixedAmount
        case orderTotalPercentage
    }

    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

    /// Defines whether the new custom amount modal is presented.
    ///
    @State private var showAddCustomAmount: Bool = false

    @State private var showAddCustomAmountConfirmationDialog: Bool = false

    @State private var addCustomAmountOption: ConfirmationOption?

    var body: some View {
        VStack {
            HStack {
                Button(Localization.addCustomAmount) {

                    onAddCustomAmountRequested()
                }
                .accessibilityIdentifier(Accessibility.addCustomAmountIdentifier)
                .buttonStyle(PlusButtonStyle())
            }
            .renderedIf(viewModel.customAmountRows.isEmpty)

            Group {
                HStack {
                    Text(Localization.customAmounts)
                        .accessibilityAddTraits(.isHeader)
                        .headlineStyle()

                    Spacer()

                    Image(uiImage: .lockImage)
                        .foregroundColor(Color(.brand))
                        .renderedIf(viewModel.shouldShowNonEditableIndicators)

                    Button(action: {
                        onAddCustomAmountRequested()
                    }) {
                        Image(uiImage: .plusImage)
                    }
                    .scaledToFit()
                    .renderedIf(!viewModel.shouldShowNonEditableIndicators)
                }

                ForEach(viewModel.customAmountRows) { customAmountRow in
                    CustomAmountRowView(viewModel: customAmountRow, editable: !viewModel.shouldShowNonEditableIndicators)
                }
            }
            .renderedIf(viewModel.customAmountRows.isNotEmpty)
        }
        .padding()
        .background(Color(.listForeground(modal: true)))
        .confirmationDialog("How do you want to add your custom amount?", isPresented: $showAddCustomAmountConfirmationDialog, titleVisibility: .visible) {
            Button("Enter as fixed amount $") {
                addCustomAmountOption = .fixedAmount
                showAddCustomAmount = true
            }

            Button("Percentage of order total %") {
                addCustomAmountOption = .orderTotalPercentage
                showAddCustomAmount = true
            }
        }
        .sheet(isPresented: $showAddCustomAmount, onDismiss: viewModel.onDismissAddCustomAmountView, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel(with: addCustomAmountOption))
        })
        .sheet(isPresented: $viewModel.showEditCustomAmount, onDismiss: viewModel.onDismissAddCustomAmountView, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel(with: addCustomAmountOption))
        })
    }
}
private extension OrderCustomAmountsSection {
    func onAddCustomAmountRequested() {
        viewModel.onAddCustomAmountButtonTapped()
        viewModel.enableAddingCustomAmountViaOrderTotalPercentage ? showAddCustomAmountConfirmationDialog.toggle() : showAddCustomAmount.toggle()
    }
}

private extension OrderCustomAmountsSection {
    enum Localization {
        static let addCustomAmount = NSLocalizedString("Add Custom Amount",
                                                   comment: "Title text of the button that allows to add a custom amount when creating or editing an order")
        static let customAmounts = NSLocalizedString("orderForm.customAmounts",
                                                     value: "Custom Amounts",
                                                     comment: "Title text of the section that shows the Custom Amounts when creating or editing an order")
    }

    enum Accessibility {
        static let addCustomAmountIdentifier = "new-order-add-custom-amount-button"
    }
}
