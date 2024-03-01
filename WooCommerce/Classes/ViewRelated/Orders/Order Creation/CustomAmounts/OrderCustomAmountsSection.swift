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
    @State private var showAddCustomAmountAfterOptionsDialog = false

    @State private var showAddCustomAmountOptionsDialog: Bool = false

    @State private var addCustomAmountOption: ConfirmationOption?

    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack {
            HStack {
                Button(Localization.addCustomAmount) {
                    onAddCustomAmountRequested()
                }
                .accessibilityIdentifier(Accessibility.addCustomAmountIdentifier)
                .buttonStyle(PlusButtonStyle())
            }
            .frame(height: Layout.rowHeight)
            .renderedIf(viewModel.customAmountRows.isEmpty)

            Group {
                HStack {
                    Text(Localization.customAmounts)
                        .accessibilityAddTraits(.isHeader)
                        .headlineStyle()

                    Spacer()

                    Image(uiImage: .lockImage)
                        .foregroundColor(Color(.primary))
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
        .padding(.horizontal, insets: safeAreaInsets)
        .if(viewModel.customAmountRows.isEmpty, transform: { $0.padding([.leading, .trailing]) })
        .if(!viewModel.customAmountRows.isEmpty, transform: { $0.padding() })
        .background(Color(.listForeground(modal: true)))
        .sheet(isPresented: $showAddCustomAmountOptionsDialog, onDismiss: onDismissOptionsDialog) {
            optionsWithDetentsBottomSheetContent
        }
        .sheet(isPresented: $viewModel.showEditCustomAmount, onDismiss: onDismissOptionsDialog) {
            optionsWithDetentsBottomSheetContent
        }
        .sheet(isPresented: $showAddCustomAmount,
               onDismiss: {
            viewModel.onDismissAddCustomAmountView()
            addCustomAmountOption = nil
        }, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel(with: addCustomAmountOption))
        })
    }

    @ViewBuilder private var optionsWithDetentsBottomSheetContent: some View {
        if #available(iOS 16.0, *) {
            optionsBottomSheetContent
                .presentationDetents([.height(218)])
                .presentationDragIndicator(.visible)
        } else {
            optionsBottomSheetContent
        }
    }

    @ViewBuilder private var optionsBottomSheetContent: some View {
        VStack (alignment: .leading, spacing: Layout.optionsBottomSheetContentVerticalSpacing) {
            Text(Localization.optionsDialogAddCustomAmountTitle)
                .subheadlineStyle()
                .padding(.top, Layout.optionsBottomSheetContentTitleTopPadding)
                .padding(.bottom, Layout.optionsBottomSheetContentTitleBottomPadding)

            HStack {
                Text("$")
                    .frame(minWidth: Layout.optionsBottomSheetButtonSymbolWidth)
                    .padding(.trailing, Layout.optionsBottomSheetButtonSymbolTrailing)

                Button(Localization.optionsDialogFixedAmountButtonTitle) {
                    addCustomAmountOption = .fixedAmount
                    showAddCustomAmountsAfterOptionsDialog()

                }
                .bodyStyle()
                .accessibilityIdentifier(Accessibility.fixedAmountIdentifier)
            }
            .padding(.bottom, Layout.optionsBottomSheetContentVerticalSpacing)

            HStack {
                Text("%")
                    .frame(minWidth: Layout.optionsBottomSheetButtonSymbolWidth)
                    .padding(.trailing, Layout.optionsBottomSheetButtonSymbolTrailing)

                Button(Localization.optionsDialogPercentageButtonTitle) {
                    addCustomAmountOption = .orderTotalPercentage
                    showAddCustomAmountsAfterOptionsDialog()
                }
                .bodyStyle()
                .accessibilityIdentifier(Accessibility.percentageAmountIdentifier)
            }

            Spacer()
        }
        .padding(.leading, Layout.optionsBottomSheetVerticalPadding)
        .padding(.trailing, Layout.optionsBottomSheetVerticalPadding)
    }
}

private extension OrderCustomAmountsSection {
    func onAddCustomAmountRequested() {
        viewModel.onAddCustomAmountButtonTapped()
        viewModel.enableAddingCustomAmountViaOrderTotalPercentage ? showAddCustomAmountOptionsDialog.toggle() : showAddCustomAmount.toggle()
    }

    func onDismissOptionsDialog() {
        if showAddCustomAmountAfterOptionsDialog {
            showAddCustomAmountAfterOptionsDialog = false
            showAddCustomAmount = true
        }
    }

    func showAddCustomAmountsAfterOptionsDialog() {
        showAddCustomAmountAfterOptionsDialog = true
        showAddCustomAmountOptionsDialog = false
        viewModel.showEditCustomAmount = false
    }
}

private extension OrderCustomAmountsSection {
    enum Layout {
        static let optionsBottomSheetContentVerticalSpacing: CGFloat = 16
        static let optionsBottomSheetContentTitleTopPadding: CGFloat = 30
        static let optionsBottomSheetContentTitleBottomPadding: CGFloat = 8
        static let optionsBottomSheetButtonSymbolWidth: CGFloat = 20
        static let optionsBottomSheetButtonSymbolTrailing: CGFloat = 18
        static let optionsBottomSheetVerticalPadding: CGFloat = 16
        static let rowHeight: CGFloat = 56

    }
    enum Localization {
        static let addCustomAmount = NSLocalizedString("Add Custom Amount",
                                                       comment: "Title text of the button that allows to add a custom amount when creating or editing an order")
        static let customAmounts = NSLocalizedString("orderForm.customAmounts",
                                                     value: "Custom Amounts",
                                                     comment: "Title text of the section that shows the Custom Amounts when creating or editing an order")
        static let optionsDialogAddCustomAmountTitle = NSLocalizedString("orderForm.customAmounts.addOptionsDialogTitle",
                                                        value: "How do you want to add your custom amount?",
                                                        comment: "Title text of the confirmation dialog that shows the add custom amounts options.")
        static let optionsDialogFixedAmountButtonTitle = NSLocalizedString("orderForm.customAmounts.addOptionsDialogFixedAmountButtonTitle",
                                                        value: "A fixed amount",
                                                        comment: "Button title for the fixed amount option in the custom amounts option sheet.")
        static let optionsDialogPercentageButtonTitle = NSLocalizedString("orderForm.customAmounts.addOptionsDialogPercentageButtonTitle",
                                                        value: "A percentage of the order total",
                                                        comment: "Button title for the percentage option in the custom amounts option sheet.")

    }

    enum Accessibility {
        static let addCustomAmountIdentifier = "new-order-add-custom-amount-button"
        static let fixedAmountIdentifier = "custom-amount-fixed-button"
        static let percentageAmountIdentifier = "custom-amount-percentage-button"
    }
}
