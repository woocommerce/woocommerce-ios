import SwiftUI
import Yosemite

/// View showing a list of products to select.
///
struct ProductSelectorView: View {
    enum Source {
        case orderForm(flow: WooAnalyticsEvent.Orders.Flow)
        case couponForm
        case couponRestrictions
    }

    let configuration: Configuration

    let source: Source

    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// Defines whether a variation list is shown.
    ///
    @State var isShowingVariationList: Bool = false

    /// View model to use for the variation list, when it is shown.
    ///
    @State var variationListViewModel: ProductVariationSelectorViewModel?

    /// View model to drive the view.
    ///
    @ObservedObject var viewModel: ProductSelectorViewModel

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets

    @State private var showingFilters: Bool = false

    @State private var searchHeaderisBeingEdited = false

    /// Tracks whether the `orderFormBundleProductConfigureCTAShown` event has been tracked to prevent multiple events across view updates.
    @State private var hasTrackedBundleProductConfigureCTAShownEvent: Bool = false

    /// Title for the multi-selection button
    ///
    private var doneButtonTitle: String {
        guard viewModel.totalSelectedItemsCount > 0 else {
            return Localization.doneButton
        }
        return String.pluralize(viewModel.totalSelectedItemsCount,
                                singular: configuration.doneButtonTitleSingularFormat,
                                plural: configuration.doneButtonTitlePluralFormat)
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchHeader(text: $viewModel.searchTerm, placeholder: Localization.searchPlaceholder, onEditingChanged: { isEditing in
                searchHeaderisBeingEdited = isEditing
            })
                .padding(.horizontal, insets: safeAreaInsets)
                .accessibilityIdentifier("product-selector-search-bar")
            Picker(selection: $viewModel.productSearchFilter, label: EmptyView()) {
                ForEach(ProductSearchFilter.allCases, id: \.self) { option in
                    Text(option.title)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.leading)
                        .padding(.trailing)
                        .renderedIf(searchHeaderisBeingEdited)
            HStack {
                Button(Localization.clearSelection) {
                    viewModel.clearSelection()
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
                .disabled(viewModel.totalSelectedItemsCount == 0 || viewModel.syncStatus != .results)
                Spacer()

                Button(viewModel.filterButtonTitle) {
                    showingFilters.toggle()
                    ServiceLocator.analytics.track(event: .ProductListFilter.productListViewFilterOptionsTapped(source: source.filterAnalyticsSource))
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
            }
            .padding(.horizontal, insets: safeAreaInsets)

            switch viewModel.syncStatus {
            case .results:
                VStack(spacing: 0) {
                    InfiniteScrollList(isLoading: viewModel.shouldShowScrollIndicator,
                                       loadAction: viewModel.syncNextPage) {
                        ForEach(viewModel.productsSectionViewModels, id: \.title) {
                            section in
                            if let title = section.title {
                                Text(title.uppercased())
                                .foregroundColor(Color(.text))
                                .footnoteStyle()
                                .padding(.top)
                                .padding(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        ForEach(section.productRows) { rowViewModel in
                            createProductRow(rowViewModel: rowViewModel)
                            .padding(Constants.defaultPadding)
                            .accessibilityIdentifier(Constants.productRowAccessibilityIdentifier)
                            Divider().frame(height: Constants.dividerHeight)
                                        .padding(.leading, Constants.defaultPadding)
                            }
                        }
                    }
                    Button(doneButtonTitle) {
                        viewModel.completeMultipleSelection()
                        isPresented.toggle()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Constants.defaultPadding)
                    .accessibilityIdentifier(Constants.doneButtonAccessibilityIdentifier)

                    if let variationListViewModel = variationListViewModel {
                        LazyNavigationLink(destination: ProductVariationSelector(
                            isPresented: $isPresented,
                            viewModel: variationListViewModel,
                            onMultipleSelections: { selectedIDs in
                                viewModel.updateSelectedVariations(productID: variationListViewModel.productID, selectedVariationIDs: selectedIDs)
                            }), isActive: $isShowingVariationList) {
                                EmptyView()
                            }
                    }
                }
                .padding(.horizontal, insets: safeAreaInsets)
                .background(Color(.listForeground(modal: false)).ignoresSafeArea())

            case .empty:
                EmptyState(title: Localization.emptyStateMessage, image: .emptyProductsTabImage)
                    .frame(maxHeight: .infinity)
            case .loading:
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
                if let cancelButtonTitle = configuration.cancelButtonTitle {
                    Button(cancelButtonTitle) {
                        isPresented.toggle()
                        if !isPresented {
                            viewModel.closeButtonTapped()
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.onLoadTrigger.send()
        }
        .notice($viewModel.notice, autoDismiss: false)
        .sheet(isPresented: $showingFilters) {
            FilterListView(viewModel: viewModel.filterListViewModel) { filters in
                viewModel.updateFilters(filters)
                ServiceLocator.analytics.track(event: .ProductListFilter
                    .productFilterListShowProductsButtonTapped(source: source.filterAnalyticsSource, filters: filters))
            } onClearAction: {
                // no-op
            } onDismissAction: {
                // no-op
            }
        }
        .interactiveDismissDisabled()
    }

    /// Creates the `ProductRow` for a product, depending on whether the product is variable.
    ///
    @ViewBuilder private func createProductRow(rowViewModel: ProductRowViewModel) -> some View {
        if let variationListViewModel = viewModel.getVariationsViewModel(for: rowViewModel.productOrVariationID) {
            HStack {
                ProductRow(multipleSelectionsEnabled: true,
                           viewModel: rowViewModel,
                           onCheckboxSelected: {
                    // In simpleSelectionMode, we immediately set the parent variable product
                    // as selected and do not navigate to the variations list.
                    if viewModel.simpleSelectionMode {
                        viewModel.changeSelectionStateForProduct(with: rowViewModel.productOrVariationID)
                        return
                    }

                    viewModel.toggleSelectionForAllVariations(of: rowViewModel.productOrVariationID)
                    // Display the variations list if toggleSelectionForAllVariations is not allowed
                    if !viewModel.toggleAllVariationsOnSelection {
                        isShowingVariationList.toggle()
                        self.variationListViewModel = variationListViewModel
                    }
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    isShowingVariationList.toggle()
                    self.variationListViewModel = variationListViewModel
                }

                DisclosureIndicator()
            }
            .accessibilityHint(configuration.variableProductRowAccessibilityHint)
        } else {
            HStack {
                ProductRow(multipleSelectionsEnabled: true,
                           viewModel: rowViewModel)
                .accessibilityHint(configuration.productRowAccessibilityHint)

                ConfigurationIndicator()
                    .renderedIf(rowViewModel.isConfigurable)
                    .onAppear {
                        guard !hasTrackedBundleProductConfigureCTAShownEvent else {
                            return
                        }
                        switch source {
                            case let .orderForm(flow):
                                ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTAShown(flow: flow, source: .productSelector))
                                hasTrackedBundleProductConfigureCTAShownEvent = true
                            default:
                                break
                        }
                    }
            }
            .onTapGesture {
                if let configure = rowViewModel.configure, rowViewModel.isConfigurable {
                    configure()
                    switch source {
                        case let .orderForm(flow):
                            ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTATapped(flow: flow, source: .productSelector))
                        default:
                            break
                    }
                } else {
                    viewModel.changeSelectionStateForProduct(with: rowViewModel.productOrVariationID)
                }
            }
        }
    }
}

extension ProductSelectorView {
    struct Configuration {
        var searchHeaderBackgroundColor: UIColor = .listForeground(modal: false)
        var prefersLargeTitle: Bool = true
        var doneButtonTitleSingularFormat: String = ""
        var doneButtonTitlePluralFormat: String = ""
        let title: String
        let cancelButtonTitle: String?
        let productRowAccessibilityHint: String
        let variableProductRowAccessibilityHint: String
    }
}

private extension ProductSelectorView {
    enum Constants {
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: CGFloat = 16
        static let doneButtonAccessibilityIdentifier: String = "product-multiple-selection-done-button"
        static let productRowAccessibilityIdentifier: String = "product-item"
    }

    enum Localization {
        static let emptyStateMessage = NSLocalizedString("No products found",
                                                         comment: "Message displayed if there are no products to display in the Select Product screen")
        static let searchPlaceholder = NSLocalizedString("Search Products", comment: "Placeholder on the search field to search for a specific product")
        static let loadingRowsAccessibilityLabel = NSLocalizedString("Loading products",
                                                                     comment: "Accessibility label for placeholder rows while products are loading")
        static let clearSelection = NSLocalizedString("Clear selection", comment: "Button to clear selection on the Select Products screen")
        static let doneButton = NSLocalizedString("Done", comment: "Button to submit the product selector without any product selected.")
    }
}

private extension ProductSelectorView.Source {
    var filterAnalyticsSource: WooAnalyticsEvent.ProductListFilter.Source {
        switch self {
            case .orderForm:
                return .orderForm
            case .couponForm:
                return .couponForm
            case .couponRestrictions:
                return .couponRestrictions
        }
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductSelectorViewModel(siteID: 123)
        let configuration = ProductSelectorView.Configuration(
            title: "Add Product",
            cancelButtonTitle: "Close",
            productRowAccessibilityHint: "Add product to order",
            variableProductRowAccessibilityHint: "Open variation list")
        ProductSelectorView(configuration: configuration, source: .orderForm(flow: .creation), isPresented: .constant(true), viewModel: viewModel)
    }
}
