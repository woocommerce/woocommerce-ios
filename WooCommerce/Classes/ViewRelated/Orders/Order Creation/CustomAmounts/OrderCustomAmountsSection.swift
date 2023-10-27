import SwiftUI

struct OrderCustomAmountsSection: View {
    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

    /// Defines whether the new custom amount modal is presented.
    ///
    @State private var showAddCustomAmount: Bool = false

    var body: some View {
        VStack {
            HStack {
                Button(Localization.addCustomAmount) {
                    viewModel.onAddCustomAmountButtonTapped()
                    showAddCustomAmount.toggle()
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
                        viewModel.onAddCustomAmountButtonTapped()
                        showAddCustomAmount.toggle()
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
        .sheet(isPresented: $showAddCustomAmount, onDismiss: viewModel.onDismissAddCustomAmountView, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel)
        })
        .sheet(isPresented: $viewModel.showEditCustomAmount, onDismiss: viewModel.onDismissAddCustomAmountView, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel)
        })
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
