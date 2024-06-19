import SwiftUI
import Yosemite

/// Hosting controller for `ProductSelectorView`.
///
final class ProductSelectorViewController: UIHostingController<ProductSelectorView> {
    init(configuration: ProductSelectorView.Configuration,
         viewModel: ProductSelectorViewModel) {

        super.init(rootView: ProductSelectorView(configuration: configuration,
                                                 isPresented: .constant(true),
                                                 viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/// View showing a list of products to select.
///
struct ProductSelectorView: View {

    let configuration: Configuration

    /// Defines whether the view is presented.
    ///
    @Binding var isPresented: Bool

    /// Defines whether the Product Selector View's width is less than the predefined row's width threshold
    /// Used so we can render a different style despite the environment's size class
    ///
    @State var isViewWidthNarrowerThanConstantRowWidth: Bool = false

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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Environment(\.adaptiveModalContainerPresentationStyle) var presentationStyle

    @ScaledMetric private var scale: CGFloat = 1.0

    /// Tracks the state for the 'Clear Selection' button
    ///
    private var isClearSelectionDisabled: Bool {
        viewModel.totalSelectedItemsCount == 0 ||
        viewModel.syncStatus != .results ||
        viewModel.selectionDisabled
    }

    /// Title for the multi-selection button
    ///
    private var doneButtonTitle: String {
        guard viewModel.totalSelectedItemsCount > 0 else {
            return Localization.doneButton
        }
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) else {
            return viewModel.selectProductsTitle
        }
        return Localization.addProductsText
    }

    /// Title for the view's navigation
    ///
    private var navigationTitle: String {
        let narrowView = (horizontalSizeClass == .compact || isViewWidthNarrowerThanConstantRowWidth)
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm),
              narrowView else {
            return configuration.title
        }
        return viewModel.selectProductsTitle
    }

    var body: some View {
        VStack(spacing: 0) {
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.sideBySideViewForOrderForm) {
                productSelectorHeader
            } else {
                legacyProductSelectorHeader
            }

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
                    .renderedIf(configuration.multipleSelectionEnabled && viewModel.syncApproach == .onButtonTap)

                    if let variationListViewModel = viewModel.productVariationListViewModel {
                        LazyNavigationLink(destination: ProductVariationSelectorView(
                            isPresented: $isPresented,
                            viewModel: variationListViewModel,
                            onMultipleSelections: { selectedIDs in
                                viewModel.updateSelectedVariations(productID: variationListViewModel.productID, selectedVariationIDs: selectedIDs)
                            }), isActive: $viewModel.isShowingProductVariationList) {
                                EmptyView()
                            }
                            .renderedIf(configuration.treatsAllProductsAsSimple == false)
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(configuration.prefersLargeTitle ? .large : .inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if let cancelButtonTitle = configuration.cancelButtonTitle {
                    Button(cancelButtonTitle) {
                        isPresented = false
                        viewModel.closeButtonTapped()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onLoadTrigger.send()
            updateSyncApproach(for: horizontalSizeClass)
        }
        .onChange(of: horizontalSizeClass, perform: { newSizeClass in
            updateSyncApproach(for: newSizeClass)
        })
        // On the order form, this is not connected; the OrderForm displays the notices.
        .notice($viewModel.notice, autoDismiss: false)
        .sheet(isPresented: $showingFilters) {
            FilterListView(viewModel: viewModel.filterListViewModel) { filters in
                viewModel.updateFilters(filters)
                ServiceLocator.analytics.track(event: .ProductListFilter
                    .productFilterListShowProductsButtonTapped(source: viewModel.source.filterAnalyticsSource, filters: filters))
            } onClearAction: {
                // no-op
            } onDismissAction: {
                // no-op
            }
        }
        .interactiveDismissDisabled()
    }

    private func updateSyncApproach(for horizontalSizeClass: UserInterfaceSizeClass?) {
        guard let horizontalSizeClass,
              let presentationStyle else {
            return
        }

        let newSyncApproach: ProductSelectorViewModel.SyncApproach
        switch horizontalSizeClass {
        case .regular:
            newSyncApproach = .external
        case .compact:
            newSyncApproach = .onButtonTap
        @unknown default:
            DDLogWarn("Unknown size class used to determine product selector sync approach")
            newSyncApproach = .onButtonTap
        }
        viewModel.syncApproach = newSyncApproach
    }

    /// Creates the `ProductRow` for a product, depending on whether the product is variable.
    ///
    @ViewBuilder private func createProductRow(rowViewModel: ProductRowViewModel) -> some View {
        if viewModel.isVariableProduct(productOrVariationID: rowViewModel.productOrVariationID),
           configuration.treatsAllProductsAsSimple == false {
            HStack {
                ProductRow(multipleSelectionsEnabled: true,
                           viewModel: rowViewModel,
                           onCheckboxSelected: {
                    viewModel.variationCheckboxTapped(for: rowViewModel.productOrVariationID)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    viewModel.variationRowTapped(for: rowViewModel.productOrVariationID)
                }
                .redacted(reason: viewModel.showPlaceholders ? .placeholder : [])
                .disabled(viewModel.selectionDisabled)

                DisclosureIndicator()
            }
            .accessibilityHint(configuration.variableProductRowAccessibilityHint)
        } else {
            HStack {
                ProductRow(multipleSelectionsEnabled: configuration.multipleSelectionEnabled,
                           viewModel: rowViewModel)
                .accessibilityHint(configuration.productRowAccessibilityHint)

                ConfigurationIndicator()
                    .renderedIf(rowViewModel.isConfigurable && configuration.treatsAllProductsAsSimple == false)
                    .onAppear {
                        guard !hasTrackedBundleProductConfigureCTAShownEvent else {
                            return
                        }
                        switch viewModel.source {
                            case let .orderForm(flow):
                                ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTAShown(flow: flow, source: .productSelector))
                                hasTrackedBundleProductConfigureCTAShownEvent = true
                            default:
                                break
                        }
                    }
            }
            .onTapGesture {
                if let configure = rowViewModel.configure, rowViewModel.isConfigurable,
                   configuration.treatsAllProductsAsSimple == false {
                    configure()
                    switch viewModel.source {
                        case let .orderForm(flow):
                            ServiceLocator.analytics.track(event: .Orders.orderFormBundleProductConfigureCTATapped(flow: flow, source: .productSelector))
                        default:
                            break
                    }
                } else if rowViewModel.selectionEnabled {
                    viewModel.changeSelectionStateForProduct(
                        with: rowViewModel.productOrVariationID,
                        selected: rowViewModel.toggledSelectedValue
                    )
                }
            }
            .redacted(reason: viewModel.showPlaceholders ? .placeholder : [])
            .disabled(viewModel.selectionDisabled)
        }
    }
}

private extension ProductSelectorView {
    @ViewBuilder var productSelectorHeader: some View {
        if horizontalSizeClass == .regular {
            productSelectorHeaderTitleRow
            productSelectorHeaderSearchRow
                .padding(.bottom, Constants.defaultPadding)
                .background(Color(.listForeground(modal: false)))
        } else {
            productSelectorHeaderSearchRow
            productSelectorHeaderTitleRow
        }
        Divider()
    }

    @ViewBuilder var legacyProductSelectorHeader: some View {
        SearchHeader(text: $viewModel.searchTerm, placeholder: Localization.searchPlaceholder, onEditingChanged: { isEditing in
            searchHeaderisBeingEdited = isEditing
        })
        .padding(.horizontal, insets: safeAreaInsets)
        .accessibilityIdentifier("product-selector-search-bar")
        Picker(selection: $viewModel.productSearchFilter, label: EmptyView()) {
            ForEach(ProductSearchFilter.allCases, id: \.self) { option in Text(option.title) }
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
            .disabled(isClearSelectionDisabled)
            .renderedIf(configuration.multipleSelectionEnabled)

            Spacer()

            Button(viewModel.filterButtonTitle) {
                showingFilters.toggle()
                ServiceLocator.analytics.track(event: .ProductListFilter.productListViewFilterOptionsTapped(source: viewModel.source.filterAnalyticsSource))
            }
            .buttonStyle(LinkButtonStyle())
            .fixedSize()
        }
        .padding(.horizontal, insets: safeAreaInsets)
    }

    @ViewBuilder private var productSelectorHeaderTitleRow: some View {
        GeometryReader { geometry in
            HStack {
                Text(viewModel.selectProductsTitle)
                    .renderedIf(configuration.productHeaderTextEnabled && geometry.size.width > Constants.headerSearchRowWidth)
                    .fixedSize()
                    .padding(.leading)
                Button(Localization.clearSelection) {
                    viewModel.clearSelection()
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
                .disabled(isClearSelectionDisabled)
                .renderedIf(configuration.multipleSelectionEnabled)

                Spacer()

                Button(viewModel.filterButtonTitle) {
                    showingFilters.toggle()
                    ServiceLocator.analytics.track(event: .ProductListFilter.productListViewFilterOptionsTapped(source: viewModel.source.filterAnalyticsSource))
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .onAppear(perform: {
                adjustViewWidthIfNeeded(using: geometry.size.width)
            })
            .onChange(of: geometry.size.width) { newViewWidth in
                adjustViewWidthIfNeeded(using: newViewWidth)
            }
        }
        .frame(height: Constants.minimumRowHeight * scale)
        .background(Color(.listForeground(modal: false)))
    }

    @ViewBuilder private var productSelectorHeaderSearchRow: some View {
        GeometryReader { geometry in
            HStack {
                SearchHeader(text: $viewModel.searchTerm, placeholder: Localization.searchPlaceholder, onEditingChanged: { isEditing in
                    searchHeaderisBeingEdited = isEditing
                })
                .submitLabel(.done)
                .accessibilityIdentifier("product-selector-search-bar")
                Picker(selection: $viewModel.productSearchFilter, label: EmptyView()) {
                    ForEach(ProductSearchFilter.allCases, id: \.self) { option in Text(option.title) }
                }
                .if(geometry.size.width <= Constants.headerSearchRowWidth) { $0.pickerStyle(.menu) }
                .if(geometry.size.width > Constants.headerSearchRowWidth) { $0.pickerStyle(.segmented) }
                .padding(.trailing)
                .renderedIf(searchHeaderisBeingEdited)
            }
        }
        // The GeometryReader will take all available space if not constrained vertically, while adjusting automatically horizontally,
        // so we need to set a desired height for this view.
        .frame(height: Constants.minimumRowHeight * scale)
        .background(Color(.listForeground(modal: false)))
    }
}

extension ProductSelectorView {
    func adjustViewWidthIfNeeded(using viewWidth: CGFloat) {
        if viewWidth <= Constants.headerSearchRowWidth {
            isViewWidthNarrowerThanConstantRowWidth = true
        } else {
            isViewWidthNarrowerThanConstantRowWidth = false
        }
    }
}

extension ProductSelectorView {
    struct Configuration {
        /// Whether more than one product can be selected.
        var multipleSelectionEnabled: Bool = true

        /// If this is false, we let users select variations for variable products and specific contents for bundle products.
        /// Otherwise, the product itself is selected immediately.
        var treatsAllProductsAsSimple: Bool = false

        var productHeaderTextEnabled: Bool = false
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
        static let minimumRowHeight: CGFloat = 48
        static let headerSearchRowWidth: CGFloat = 450
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
        static let addProductsText = NSLocalizedString(
            "productselectorview.doneButtonTitle.addProductsText",
            value: "Add Products",
            comment: "Button to submit selected products to the order, when some product has been selected.")
    }
}

private extension ProductSelectorSource {
    var filterAnalyticsSource: WooAnalyticsEvent.ProductListFilter.Source {
        switch self {
            case .orderForm:
                return .orderForm
            case .couponForm:
                return .couponForm
            case .couponRestrictions:
                return .couponRestrictions
        case .blaze:
            return .blaze
        case .orderFilter:
            return .orderFilter
        }
    }
}

struct AddProduct_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductSelectorViewModel(siteID: 123, source: .orderForm(flow: .creation))
        let configuration = ProductSelectorView.Configuration(
            title: "Add Product",
            cancelButtonTitle: "Close",
            productRowAccessibilityHint: "Add product to order",
            variableProductRowAccessibilityHint: "Open variation list")
        ProductSelectorView(configuration: configuration, isPresented: .constant(true), viewModel: viewModel)
    }
}
