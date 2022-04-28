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

    @State private var showingFilter: Bool = false

    /// Title for the multi-selection button
    ///
    private var doneButtonTitle: String {
        String.pluralize(viewModel.totalSelectedItemsCount,
                         singular: configuration.doneButtonTitleSingularFormat,
                         plural: configuration.doneButtonTitlePluralFormat)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchHeader(filterText: $viewModel.searchTerm, filterPlaceholder: Localization.searchPlaceholder)
                    .padding(.horizontal, insets: safeAreaInsets)
                HStack {
                    Button(viewModel.selectAllButtonTitle) {
                        // TODO: handle selecting all
                    }
                    .buttonStyle(LinkButtonStyle())
                    .fixedSize()
                    .renderedIf(configuration.multipleSelectionsEnabled && viewModel.syncStatus == .results)

                    Spacer()

                    Button(viewModel.filterButtonTitle) {
                        showingFilter.toggle()
                    }
                    .buttonStyle(LinkButtonStyle())
                    .fixedSize()
                    .renderedIf(configuration.showsFilter)
                }

                switch viewModel.syncStatus {
                case .results:
                    VStack(spacing: 0) {
                        InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                           loadAction: viewModel.syncNextPage) {
                            ForEach(viewModel.productRows) { rowViewModel in
                                createProductRow(rowViewModel: rowViewModel)
                                    .padding(Constants.defaultPadding)
                                Divider().frame(height: Constants.dividerHeight)
                                    .padding(.leading, Constants.defaultPadding)
                            }
                        }
                        if viewModel.totalSelectedItemsCount > 0 {
                            Button(doneButtonTitle) {
                                viewModel.completeMultipleSelection()
                                isPresented.toggle()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(Constants.defaultPadding)
                        }
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Color(.listForeground).ignoresSafeArea())

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
            .onDisappear {
                viewModel.clearSearchAndFilters()
            }
            .notice($viewModel.notice, autoDismiss: false)
            .sheet(isPresented: $showingFilter) {
                FilterListView(viewModel: viewModel.filterListViewModel) { filters in
                    viewModel.filters = filters
                } onClearAction: {
                    // no-op
                } onDismissAction: {
                    // no-op
                }
            }
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
        var doneButtonTitleSingularFormat: String = ""
        var doneButtonTitlePluralFormat: String = ""
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
