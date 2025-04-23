import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

@available(iOS 17.0, *)
struct ItemListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(PointOfSaleAggregateModel.self) private var posModel

    @Environment(\.keyboardObserver) private var keyboardObserver

    @Binding var selectedItemListType: ItemListType
    @Binding var searchTerm: String

    @FocusState private var isSearchFieldFocused: Bool

    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true

    private var isCouponsFeatureEnabled: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale)
    }

    private var isSearchProductsFeatureEnabled: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.searchProductsInPOS)
    }

    private var isAddingCouponAllowed: Bool {
        guard case .coupons = selectedItemListType else { return false }
        let itemListState = itemListState(selectedItemListType)
        return itemListState.isLoaded || itemListState.isEmpty
    }

    private var isSearchAllowed: Bool {
        guard isSearchProductsFeatureEnabled else {
            return false
        }
        switch selectedItemListType {
        case .products:
            return true
        case .coupons:
            return false
        }
    }

    private var shouldShowHeaderItems: Bool {
        !selectedItemListType.isSearching
    }

    @State private var showCouponCreationModal: Bool = false

    var body: some View {
        if #available(iOS 18.0, *) {
            NavigationStack {
                content
            }
        } else {
            // On iOS 17, NavigationStack causes memory leaks when the POS is closed, NavigationView is a fallback.
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            headerView

            TabView(selection: $selectedItemListType) {
                itemListContent(.products(search: false))
                if isSearchProductsFeatureEnabled {
                    itemListContent(.products(search: true))
                }
                if isCouponsFeatureEnabled {
                    itemListContent(.coupons)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.none, value: selectedItemListType)
            .ignoresSafeArea()
        }

        // N.B. This navigationDestination causes a runtime warning in iOS 17, and is ignored. On iOS 17,
        // the navigation is handled in a NavigationLink in ItemList.swift. Avoiding the warning is impractical.
        .navigationDestination(for: POSItem.self, destination: { item in
            childListView(parentItem: item)
        })
        .background(Color.posSurface)
        .accessibilityElement(children: .contain)
        .posCouponCreationSheet(isPresented: $showCouponCreationModal, onSuccess: { couponItem in
            Task { @MainActor in
                posModel.addToCart(couponItem)
                await posModel.couponsController.refreshItems(base: .root)
            }
        })
    }

    @ViewBuilder
    private func itemListContent(_ itemListType: ItemListType) -> some View {
        Group {
            if itemListType.isSearching && searchTerm.isEmpty {
                POSRecentSearchesView(
                    savedSearches: posModel.searchHistory(for: itemListType.itemType),
                    onSearchSelected: { search in
                        searchTerm = search
                        ServiceLocator.analytics.track(
                            event: WooAnalyticsEvent.PointOfSale.preSearchRecentTermTapped(itemListType: itemListType))
                    }
                )
                .background(Color.posSurface)
            } else {
                switch itemListState(itemListType) {
                case .loading(let items),
                        .loaded(let items, _),
                        .inlineError(let items, _, _):
                    listView(items, itemListType: itemListType)
                case .error(let errorState):
                    errorView(errorState)
                    EmptyView()
                case .empty:
                    emptyView
                }
            }
        }
        .tag(itemListType)
        .gesture(DragGesture()) // Disable a default swipe gesture between the tabs
    }
}

/// View Helpers
///
@available(iOS 17.0, *)
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            POSPageHeaderView(items: headerViewItems, trailingContent: {
                HStack {
                    if isSearchAllowed {
                        searchField
                            .renderedIf(selectedItemListType.isSearching)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .onChange(of: searchTerm) { oldValue, newValue in
                                // The debouncing logic is a little tricky, because the loading state is held in the controller.
                                // Arguably, we should use view state `isSearching` for this, so the UI is independent of the request timing.

                                // As the user types, we don't want to send every keystroke to the remote, so we debounce the requests.
                                // However, we don't want to debounce the first keystroke of a new search, so that the loading
                                // state shows immediately and the UI feels responsive.

                                // So, if the last search was finished, we don't debounce the first character. If it didn't
                                // finish i.e. it is still ongoing, we debounce the next keystrokes by 300ms. In either case,
                                // the ongoing search is redundant now there's a new search term, so we cancel it.
                                let shouldDebounceNextSearchRequest = !didFinishSearch
                                searchTask?.cancel()

                                searchTask = Task {
                                    if shouldDebounceNextSearchRequest {
                                        try? await Task.sleep(nanoseconds: 300 * NSEC_PER_MSEC)
                                    }

                                    guard !Task.isCancelled else { return }

                                    guard searchTerm.isNotEmpty else {
                                        didFinishSearch = true
                                        return
                                    }

                                    didFinishSearch = false

                                    await posModel.purchasableItemsSearchController.searchItems(searchTerm: newValue, baseItem: .root)

                                    if !Task.isCancelled {
                                        didFinishSearch = true
                                    }
                                }
                            }

                        POSPageHeaderActionButton(systemName: "magnifyingglass") {
                            withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                                ServiceLocator.analytics.track(event: WooAnalyticsEvent.PointOfSale.searchButtonTapped(
                                    itemListType: selectedItemListType))
                                selectedItemListType = .products(search: true)
                            } completion: {
                                isSearchFieldFocused = true
                            }
                        }
                        .renderedIf(!selectedItemListType.isSearching)
                        .transition(.opacity.combined(with: .scale))
                    }

                    if isCouponsFeatureEnabled {
                        POSPageHeaderActionButton(systemName: "plus") {
                            ServiceLocator.analytics.track(.pointOfSaleCouponsCreateTapped)
                            showCouponCreationModal = true
                        }
                        .renderedIf(isAddingCouponAllowed)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            })
        }
        .animation(.easeInOut(duration: Constants.animationDuration), value: selectedItemListType.isSearching)
        .animation(.easeInOut(duration: Constants.animationDuration), value: isAddingCouponAllowed)
        .animation(.easeInOut(duration: Constants.animationDuration), value: searchTerm)
    }

    var headerViewItems: [POSPageHeaderItem] {
        guard shouldShowHeaderItems else {
            return []
        }
        var items = [
            POSPageHeaderItem(
                title: Localization.productsTitle,
                isSelected: selectedItemListType.isProducts,
                action: {
                    displayItemListType(.products(search: searchTerm.isNotEmpty))
                }
            )
        ]

        if isCouponsFeatureEnabled {
            items.append(
                POSPageHeaderItem(
                    title: Localization.couponsTitle,
                    isSelected: selectedItemListType.isCoupons,
                    action: {
                        displayItemListType(.coupons)
                    }
                )
            )
        }

        return items
    }

    var searchField: some View {
        HStack(spacing: POSSpacing.small) {
            Button {
                searchTerm = ""
                isSearchFieldFocused = false
                withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                    selectedItemListType = .products(search: false)
                }
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.posOnSurface)
                    .font(.posButtonSymbolLarge)
            }

            TextField(text: $searchTerm) {
                Text(Localization.searchFieldLabel)
            }
            .font(POSFontStyle.posBodyLargeRegular())
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($isSearchFieldFocused)

            Button {
                searchTerm = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .accessibilityLabel(Localization.searchFieldClearButtonAccessibilityLabel)
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .font(.posButtonSymbolSmall)
            }
            .transition(.opacity)
            .renderedIf(searchTerm.isNotEmpty)
        }
        .onChange(of: keyboardObserver.isKeyboardVisible) { _, isVisible in
            guard isVisible == false else {
                return
            }
            ServiceLocator.analytics.track(.pointOfSaleKeyboardDismissedInSearch)
        }
    }

    @ViewBuilder
    func listView(_ items: [POSItem], itemListType: ItemListType) -> some View {
        ItemList(
            itemsController: itemsController(itemListType),
            node: .root,
            itemActionHandler: actionHandler(itemListType),
            willLoadMore: {
                ServiceLocator.analytics.track(
                    event: WooAnalyticsEvent.PointOfSale.pointOfSaleItemsNextPageLoaded(itemListType: selectedItemListType))
            }
        )
        .refreshable {
            trackPullToRefresh()
            await itemsController(itemListType).refreshItems(base: .root)
        }
    }

    private func actionHandler(_ itemListType: ItemListType) -> POSItemActionHandler {
        switch itemListType {
        case .products(search: false), .coupons:
            StandardPOSItemActionHandler(posModel: posModel, itemListType: selectedItemListType)
        case .products(search: true):
            SearchResultItemActionHandler(posModel: posModel, searchTerm: searchTerm, itemListType: itemListType)
        }
    }

    @ViewBuilder
    func childListView(parentItem: POSItem) -> some View {
        // Note that navigation is handled by the ItemList in iOS 17, so any changes to this should be reflected in ItemListRow.
        switch parentItem {
        case let .variableParentProduct(parentProduct):
            // This always uses the non-search itemsController, otherwise it will have the search term and not work properly
            // This is a temporary fix until we tidy up the stack selection, as it means non-products child lists won't work.
            ChildItemList(
                parentItem: parentItem,
                title: parentProduct.name,
                itemsController: posModel.purchasableItemsController,
                itemActionHandler: actionHandler(selectedItemListType)
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    var emptyView: some View {
        switch selectedItemListType {
        case .products:
            PointOfSaleItemListEmptyView(
                viewModel: PointOfSaleItemListEmptyViewModel(
                    itemListType: selectedItemListType,
                    baseItem: .root))
        case .coupons:
            PointOfSaleItemListEmptyView(
                viewModel: PointOfSaleItemListEmptyViewModel(
                    itemListType: selectedItemListType,
                    baseItem: .root)) {
                showCouponCreationModal = true
            }
        }
    }

    @ViewBuilder
    func errorView(_ errorState: PointOfSaleErrorState) -> some View {
        switch errorState {
        case .errorCouponsDisabled, .errorOnEnablingCoupons:
            PointOfSaleItemListErrorView(error: errorState, onAction: {
                Task {
                    await posModel.couponsController.enableCoupons()
                    ServiceLocator.analytics.track(.couponSettingEnabled)
                }
            })
        default:
            PointOfSaleItemListErrorView(error: errorState, onAction: {
                Task {
                    await itemsController(selectedItemListType).loadItems(base: .root)
                }
            })
        }
    }
}

@available(iOS 17.0, *)
private extension ItemListView {
    func displayItemListType(_ itemListType: ItemListType) {
        selectedItemListType = itemListType
        Task { @MainActor in
            if itemListState(itemListType).items.isEmpty {
                await itemsController(itemListType).loadItems(base: .root)
            }
        }

        trackSelectedItemListTypeTapped(itemListType)
    }
}

@available(iOS 17.0, *)
private extension ItemListView {
    func itemsController(_ itemType: ItemListType) -> PointOfSaleItemsControllerProtocol {
        switch itemType {
        case .products(search: false):
            posModel.purchasableItemsController
        case .products(search: true):
            posModel.purchasableItemsSearchController
        case .coupons:
            posModel.couponsController
        }
    }

    private func itemListState(_ itemType: ItemListType) -> ItemListState {
        itemsController(itemType).itemsViewState.itemsStack.root
    }
}

/// Constants
///
@available(iOS 17.0, *)
private extension ItemListView {
    enum Constants {
        static let animationDuration: CGFloat = 0.2
    }

    enum BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }

    enum Localization {
        static let productsTitle = NSLocalizedString(
            "pos.itemlistview.title",
            value: "Products",
            comment: "Title at the top of the Point of Sale product selector screen."
        )

        static let couponsTitle = NSLocalizedString(
            "pos.itemlistview.couponsTitle",
            value: "Coupons",
            comment: "Title of the button at the top of Point of Sale to switch to Coupons list."
        )

        static let searchFieldLabel = NSLocalizedString(
            "pos.itemlistview.searchField.label",
            value: "Search products",
            comment: "Label/placeholder text for the product search field in Point of Sale."
        )

        static let searchFieldClearButtonAccessibilityLabel = NSLocalizedString(
            "pos.itemlistview.searchField.clearButton.accessibilityLabel",
            value: "Clear Search",
            comment: "Accessibility label for the clear button in the Point of Sale product search screen."
        )
    }
}

@available(iOS 17.0, *)
private extension ItemListView {
    func trackSelectedItemListTypeTapped(_ type: ItemListType) {
        switch type {
        case .products:
            ServiceLocator.analytics.track(.pointOfSaleProductsTapped)
        case .coupons:
            ServiceLocator.analytics.track(.pointOfSaleCouponsTapped)
        }
    }

    func trackPullToRefresh() {
        switch selectedItemListType {
        case .products:
            ServiceLocator.analytics.track(.pointOfSaleProductsPullToRefresh)
        case .coupons:
            ServiceLocator.analytics.track(.pointOfSaleCouponsPullToRefresh)
        }
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Loaded with all product types") {
    let itemsController = PointOfSalePreviewItemsController()
    Task { @MainActor in
        await itemsController.loadItems(base: .root)
    }
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(itemsController: itemsController)
    return ItemListView(selectedItemListType: .constant(.products(search: false)),
                        searchTerm: .constant(""))
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Loading") {
    ItemListView(selectedItemListType: .constant(.products(search: false)),
                 searchTerm: .constant(""))
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
