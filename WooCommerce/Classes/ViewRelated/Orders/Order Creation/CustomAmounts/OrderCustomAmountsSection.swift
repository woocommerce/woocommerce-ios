import SwiftUI
import WooFoundation

/// View model for `OrderCustomAmountsSection` that controls the visibility states of modals from various sources.
final class OrderCustomAmountsSectionViewModel: ObservableObject {
    /// Defines whether the new custom amount modal is presented.
    @Published var showAddCustomAmount: Bool = false

    /// Defines whether the custom amount options dialog is presented.
    @Published var showCustomAmountOptionsDialog: Bool = false

    let currencySettings: CurrencySettings
    init(currencySettings: CurrencySettings) {
        self.currencySettings = currencySettings
    }

    /// The site's currency symbol. When we support creating orders in other currencies,
    /// the appropriate code will need to be passed in from the EditableOrderViewModel.
    var currencySymbol: String {
        currencySettings.currencySymbol
    }
}

struct OrderCustomAmountsSection: View {
    enum ConfirmationOption {
        case fixedAmount
        case orderTotalPercentage
    }

    /// View model to drive the view content
    @ObservedObject var viewModel: EditableOrderViewModel

    @ObservedObject var sectionViewModel: OrderCustomAmountsSectionViewModel

    /// Defines whether the new custom amount modal is presented after selecting an option from the dialog.
    ///
    @State private var showAddCustomAmountAfterOptionsDialog = false

    @State private var addCustomAmountOption: ConfirmationOption?

    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack {
            HStack {
                Button(Localization.addCustomAmount) {
                    onAddCustomAmountRequested()
                }
                .accessibilityIdentifier(Accessibility.addCustomAmountIdentifier)
                .buttonStyle(PlusButtonStyle())
            }
            .frame(minHeight: Layout.rowHeight)
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
        .popover(isPresented: isCustomAmountOptionsPopoverPresented) {
            optionsPopoverContent
        }
        .sheet(isPresented: isCustomAmountOptionsSheetPresented) {
            optionsWithDetentsBottomSheetContent
        }
        .sheet(isPresented: $sectionViewModel.showAddCustomAmount,
               onDismiss: {
            viewModel.onDismissAddCustomAmountView()
            addCustomAmountOption = nil
        }, content: {
            AddCustomAmountView(viewModel: viewModel.addCustomAmountViewModel(with: addCustomAmountOption))
        })
    }

    // Computed bindings based on horizontalSizeClass
    private var isCustomAmountOptionsPopoverPresented: Binding<Bool> {
        Binding(
            get: { sectionViewModel.showCustomAmountOptionsDialog && horizontalSizeClass == .regular },
            set: { newValue in
                if horizontalSizeClass == .regular {
                    sectionViewModel.showCustomAmountOptionsDialog = newValue
                }
            }
        )
    }

    private var isCustomAmountOptionsSheetPresented: Binding<Bool> {
        Binding(
            get: { sectionViewModel.showCustomAmountOptionsDialog && horizontalSizeClass == .compact },
            set: { newValue in
                if horizontalSizeClass == .compact {
                    sectionViewModel.showCustomAmountOptionsDialog = newValue
                }
            }
        )
    }

    @ViewBuilder private var optionsPopoverContent: some View {
        optionsBottomSheetContent
            .frame(width: optionsPopoverSize.width, height: optionsPopoverSize.height)
    }

    private var optionsPopoverSize: CGSize {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return CGSize(width: 325, height: 175)
        case .medium, .large:
            return CGSize(width: 375, height: 175)
        case .xLarge:
            return CGSize(width: 400, height: 175)
        case .xxLarge, .xxxLarge:
            return CGSize(width: 400, height: 200)
        case .accessibility1:
            return CGSize(width: 475, height: 225)
        case .accessibility2:
            return CGSize(width: 550, height: 250)
        case .accessibility3:
            return CGSize(width: 550, height: 350)
        case .accessibility4, .accessibility5:
            return CGSize(width: 550, height: 400)
        @unknown default:
            return CGSize(width: 550, height: 350)
        }
    }

    @ViewBuilder private var optionsWithDetentsBottomSheetContent: some View {
        optionsBottomSheetContent
            .presentationDetents(detentsForOptionsBottomSheet)
            .presentationDragIndicator(.visible)
    }

    private var detentsForOptionsBottomSheet: Set<PresentationDetent> {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return [.height(175), .medium]
        case .xLarge, .xxLarge:
            return [.height(200), .medium]
        case .xxxLarge:
            return [.height(230), .medium]
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return [.medium, .large]
        @unknown default:
            return [.large]
        }
    }

    @ViewBuilder private var optionsBottomSheetContent: some View {
        VStack (alignment: .leading, spacing: Layout.optionsBottomSheetContentVerticalSpacing) {
            Text(Localization.optionsDialogAddCustomAmountTitle)
                .subheadlineStyle()
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Layout.optionsBottomSheetContentVerticalSpacing)
                .padding([.leading, .trailing], Layout.optionsBottomSheetPadding)

            List {
                Button {
                    addCustomAmountOption = .fixedAmount
                    showAddCustomAmountsAfterOptionsDialog()
                } label: {
                    optionLabel(symbol: sectionViewModel.currencySymbol,
                                title: Localization.optionsDialogFixedAmountButtonTitle)
                }
                .listRowSeparator(.hidden)
                .accessibilityIdentifier(Accessibility.fixedAmountIdentifier)

                Button {
                    addCustomAmountOption = .orderTotalPercentage
                    showAddCustomAmountsAfterOptionsDialog()
                } label: {
                    optionLabel(symbol: "%",
                                title: Localization.optionsDialogPercentageButtonTitle)
                }
                .listRowSeparator(.hidden)
                .accessibilityIdentifier(Accessibility.percentageAmountIdentifier)
            }
            .listStyle(.plain)
        }
        .padding([.top, .bottom], Layout.optionsBottomSheetPadding)
    }

    @ViewBuilder private func optionLabel(symbol: String, title: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Text(symbol)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bodyStyle()
    }
}

private extension OrderCustomAmountsSection {
    func onAddCustomAmountRequested() {
        viewModel.onAddCustomAmountButtonTapped()
    }

    func showAddCustomAmountsAfterOptionsDialog() {
        sectionViewModel.showCustomAmountOptionsDialog = false
        sectionViewModel.showAddCustomAmount = true
    }
}

private extension OrderCustomAmountsSection {
    enum Layout {
        static let optionsBottomSheetContentVerticalSpacing: CGFloat = 16
        static let optionsBottomSheetContentTitleBottomPadding: CGFloat = 8
        static let optionsBottomSheetSymbolLabelSpacing: CGFloat = 18
        static let optionsBottomSheetPadding: CGFloat = 16
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
