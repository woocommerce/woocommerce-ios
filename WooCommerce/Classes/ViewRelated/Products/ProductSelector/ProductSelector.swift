import SwiftUI

/// View showing a list of products to select.
///
struct ProductSelector: View {

    let configuration: Configuration

    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductSelectorViewModel

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    var body: some View {
        NavigationView {
            VStack {
                SearchHeader(filterText: $viewModel.searchTerm, filterPlaceholder: Localization.searchPlaceholder)
                    .padding(.horizontal, insets: safeAreaInsets)
                switch viewModel.syncStatus {
                case .results:
                    VStack(spacing: 0) {
                        HStack {
                            Button(Localization.selectAllButton) {
                                // TODO: handle selecting all
                            }
                            .buttonStyle(LinkButtonStyle())
                            .fixedSize()
                            .renderedIf(configuration.multipleSelectionsEnabled)
                            Spacer()
                            Button(Localization.filterButton) {
                                // TODO: handle filter
                            }
                            .buttonStyle(LinkButtonStyle())
                            .fixedSize()
                            .renderedIf(configuration.showsFilter)
                        }
                        InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                           loadAction: viewModel.syncNextPage) {
                            ForEach(viewModel.productRows) { rowViewModel in
                                createProductRow(rowViewModel: rowViewModel)
                                    .padding(Constants.defaultPadding)
                                Divider().frame(height: Constants.dividerHeight)
                                    .padding(.leading, Constants.defaultPadding)
                            }
                            .padding(.horizontal, insets: safeAreaInsets)
                            .background(Color(.listForeground).ignoresSafeArea())
                        }
                        if viewModel.totalSelectedItemsCount > 0 {
                            Button(String.localizedStringWithFormat(configuration.doneButtonTitleFormat, viewModel.totalSelectedItemsCount)) {
                                viewModel.completeMultipleSelection()
                                isPresented.toggle()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(Constants.defaultPadding)
                        }
                    }

                case .empty:
                    EmptyState(title: Localization.emptyStateMessage, image: .emptyProductsTabImage)
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
            .background(Color(configuration.searchHeaderBackgroundColor).ignoresSafeArea())
            .ignoresSafeArea(.container, edges: .horizontal)
            .navigationTitle(configuration.title)
            .navigationBarTitleDisplayMode(configuration.prefersLargeTitle ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(configuration.cancelButtonTitle) {
                        isPresented.toggle()
                    }
                }
            }
            .onAppear {
                viewModel.onLoadTrigger.send()
            }
            .notice($viewModel.notice, autoDismiss: false)
        }
        .wooNavigationBarStyle()
    }

    /// Creates the `ProductRow` for a product, depending on whether the product is variable.
    ///
    @ViewBuilder private func createProductRow(rowViewModel: ProductRowViewModel) -> some View {
        if let addVariationToOrderVM = viewModel.getVariationsViewModel(for: rowViewModel.productOrVariationID) {
            LazyNavigationLink(destination: ProductVariationSelector(
                isPresented: $isPresented,
                viewModel: addVariationToOrderVM,
                multipleSelectionsEnabled: configuration.multipleSelectionsEnabled,
                onMultipleSelections: { selectedIDs in
                    viewModel.updateSelectedVariations(productID: rowViewModel.productOrVariationID, selectedVariationIDs: selectedIDs)
                })) {
                HStack {
                    ProductRow(multipleSelectionsEnabled: configuration.multipleSelectionsEnabled,
                               viewModel: rowViewModel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DisclosureIndicator()
                }
            }
            .accessibilityHint(configuration.variableProductRowAccessibilityHint)
        } else {
            ProductRow(multipleSelectionsEnabled: configuration.multipleSelectionsEnabled,
                       viewModel: rowViewModel)
                .accessibilityHint(configuration.productRowAccessibilityHint)
                .onTapGesture {
                    viewModel.selectProduct(rowViewModel.productOrVariationID)
                    if !configuration.multipleSelectionsEnabled {
                        isPresented.toggle()
                    }
                }
        }
    }
}

extension ProductSelector {
    struct Configuration {
        var showsFilter: Bool = false
        var multipleSelectionsEnabled: Bool = false
        var searchHeaderBackgroundColor: UIColor = .listForeground
        var prefersLargeTitle: Bool = true
        var doneButtonTitleFormat: String = ""
        let title: String
        let cancelButtonTitle: String
        let productRowAccessibilityHint: String
        let variableProductRowAccessibilityHint: String
    }
}

private extension ProductSelector {
    enum Constants {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: CGFloat = 16
    }

    enum Localization {
        static let emptyStateMessage = NSLocalizedString("No products found",
                                                         comment: "Message displayed if there are no products to display in the Select Product screen")
        static let searchPlaceholder = NSLocalizedString("Search Products", comment: "Placeholder on the search field to search for a specific product")
        static let loadingRowsAccessibilityLabel = NSLocalizedString("Loading products",
                                                                     comment: "Accessibility label for placeholder rows while products are loading")
        static let selectAllButton = NSLocalizedString("Select All", comment: "Title of the button to select all products in the Select Product screen")
        static let unSelectAllButton = NSLocalizedString("Unselect All", comment: "Title of the Button to unselect all products in the Select Product screen")
        static let filterButton = NSLocalizedString("Filter", comment: "Title of the button to select all products in the Select Product screen")
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductSelectorViewModel(siteID: 123)
        let configuration = ProductSelector.Configuration(
            showsFilter: true,
            multipleSelectionsEnabled: true,
            title: "Add Product",
            cancelButtonTitle: "Close",
            productRowAccessibilityHint: "Add product to order",
            variableProductRowAccessibilityHint: "Open variation list")
        ProductSelector(configuration: configuration, isPresented: .constant(true), viewModel: viewModel)
    }
}
