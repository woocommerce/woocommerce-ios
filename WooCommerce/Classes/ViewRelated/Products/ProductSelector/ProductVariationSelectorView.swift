import SwiftUI

/// View showing a list of product variations to select.
///
struct ProductVariationSelectorView: View {
    @Environment(\.presentationMode) private var presentation

    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// View model to drive the view.
    ///
    @ObservedObject private var viewModel: ProductVariationSelectorViewModel

    private let onMultipleSelections: (([Int64]) -> Void)?

    /// Tracks the state for the 'Clear Selection' button
    ///
    private var isClearSelectionDisabled: Bool {
        viewModel.selectedProductVariationIDs.isEmpty ||
        viewModel.syncStatus != .results ||
        viewModel.selectionDisabled
    }

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    init(isPresented: Binding<Bool>,
         viewModel: ProductVariationSelectorViewModel,
         onMultipleSelections: (([Int64]) -> Void)? = nil) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self.onMultipleSelections = onMultipleSelections
    }

    var body: some View {
        Group {
            switch viewModel.syncStatus {
            case .results:
                VStack(alignment: .leading, spacing: 0) {
                    Button(Localization.clearSelection) {
                        viewModel.clearSelection()
                    }
                    .buttonStyle(LinkButtonStyle())
                    .fixedSize()
                    .disabled(isClearSelectionDisabled)

                    InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                       loadAction: viewModel.syncNextPage) {
                        ForEach(viewModel.productVariationRows) { rowViewModel in
                            ProductRow(multipleSelectionsEnabled: true,
                                       viewModel: rowViewModel)
                                .accessibilityHint(Localization.productRowAccessibilityHint)
                                .padding(Constants.defaultPadding)
                                .redacted(reason: viewModel.selectionDisabled ? .placeholder : [])
                                .disabled(viewModel.selectionDisabled)
                                .onTapGesture {
                                    viewModel.changeSelectionStateForVariation(with: rowViewModel.productOrVariationID,
                                                                               selected: rowViewModel.toggledSelectedValue)
                                }
                            Divider().frame(height: Constants.dividerHeight)
                                .padding(.leading, Constants.defaultPadding)
                        }
                    }
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground(modal: false)).ignoresSafeArea())
            case .empty:
                EmptyState(title: Localization.emptyStateMessage, image: .productBlouseImage)
                    .frame(maxHeight: .infinity)
            case .firstPageSync:
                List(viewModel.ghostRows) { rowViewModel in
                    ProductRow(viewModel: rowViewModel)
                        .redacted(reason: .placeholder)
                        .accessibilityRemoveTraits(.isButton)
                        .accessibilityLabel(Localization.loadingRowsAccessibilityLabel)
                        .shimmering()
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .listStyle(PlainListStyle())
            default:
                EmptyView()
            }
        }
        .background(Color(.listBackground).ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .horizontal)
        .navigationTitle(viewModel.productName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Minimal back button
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onMultipleSelections?(viewModel.selectedProductVariationIDs)
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(uiImage: .chevronLeftImage).flipsForRightToLeftLayoutDirection(true)
                }
                .accessibilityLabel(Localization.backButtonAccessibilityLabel)
            }
        }
        .onAppear {
            viewModel.onLoadTrigger.send()
        }
        .notice($viewModel.notice, autoDismiss: false)
        .interactiveDismissDisabled()
    }
}

private extension ProductVariationSelectorView {
    enum Constants {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: CGFloat = 16
    }

    enum Localization {
        static let emptyStateMessage = NSLocalizedString("No product variations found",
                                                         comment: "Message displayed if there are no product variations for a product.")

        static let backButtonAccessibilityLabel = NSLocalizedString("Back", comment: "This text appears as the accessibility label for back navigation buttons in various screens throughout the WooCommerce app, including web view navigation, shipping label package creation, and product variation selection screens. It helps screen readers identify the back button functionality for visually impaired users.")
        static let productRowAccessibilityHint = NSLocalizedString("Adds variation to order.",
                                                                   comment: "This is an accessibility hint that screen readers announce when a user focuses on a product variation row in the variation selector screen, explaining that tapping the row will add that variation to their order.")
        static let loadingRowsAccessibilityLabel = NSLocalizedString("Loading product variations",
                                                                     comment: "Accessibility label for placeholder rows while product variations are loading")
        static let clearSelection = NSLocalizedString("Clear selection", comment: "Button label that appears on product selection screens (both main product selector and product variation selector) allowing users to clear their current selection of products or variations when building orders.")
    }
}

struct AddProductVariationToOrder_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductVariationSelectorViewModel(
            siteID: 1,
            productID: 2,
            productName: "Monstera Plant",
            productAttributes: [],
            selectedProductVariationIDs: []
        )

        ProductVariationSelectorView(isPresented: .constant(true), viewModel: viewModel)
    }
}
