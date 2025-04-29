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

    private var _isSearching: Binding<Bool> {
        Binding(
            get: {
                switch selectedItemListType {
                case .products(search: let searching):
                    return searching
                case .coupons(search: let searching):
                    return searching
                }
            },
            set: { newValue in
                switch selectedItemListType {
                case .products:
                    selectedItemListType = .products(search: newValue)
                case .coupons:
                    selectedItemListType = .coupons(search: newValue)
                }
            }
        )
    }

    private var isSearching: Bool {
        _isSearching.wrappedValue
    }

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
        // Temporary:
        // Handle feature flag for coupon search when trunk merged
        switch selectedItemListType {
        case .products:
            return isSearchProductsFeatureEnabled
        case .coupons:
            return true
        }
    }

    private var shouldShowHeaderItems: Bool {
        !isSearching
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
                itemListTabContent(.products(search: false))
                if isCouponsFeatureEnabled {
                    itemListTabContent(.coupons(search: false))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.none, value: selectedItemListType)
            // Respect the keyboard safe area when a full keyboard is shown, but not the external keyboard shortcut bar.
            .ignoresSafeArea(keyboardObserver.isFullSizeKeyboardVisible ? .container : [.keyboard, .container])
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

    private var searchItemsController: PointOfSaleSearchingItemsControllerProtocol {
        switch selectedItemListType {
        case .products:
            return posModel.purchasableItemsSearchController
        case .coupons:
            return posModel.couponsSearchController
        }
    }

    @ViewBuilder
    private func itemListTabContent(_ itemListType: ItemListType) -> some View {
        ZStack {
            itemListContent(itemListType)

            if isSearching {
                POSSearchContentView(
                    // TODO:
                    // - searchHistoryProvider needs to be updated to switch between Products and Coupons history when needed
                    searchable: POSProductSearchable(itemListType: selectedItemListType,
                                                     itemsController: searchItemsController,
                                                     searchHistoryProvider: posModel.searchHistoryService),
                    searchTerm: $searchTerm
                ) { _ in
                    itemListContent(selectedItemListType)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .zIndex(1)
            }
        }
        .tag(itemListType)
        .gesture(DragGesture()) // Disable a default swipe gesture between the tabs
    }

    @ViewBuilder
    private func itemListContent(_ itemListType: ItemListType) -> some View {
        switch itemListState(itemListType) {
        case .loading(let items),
                .loaded(let items, _),
                .inlineError(let items, _, _):
            listView(items, itemListType: itemListType)
        case .error(let errorState):
            errorView(errorState)
        case .empty:
            emptyView
        }
    }

    @ViewBuilder
    private func listView(_ items: [POSItem], itemListType: ItemListType) -> some View {
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
        case .products(search: false), .coupons(search: false):
            StandardPOSItemActionHandler(posModel: posModel, itemListType: selectedItemListType)
        case .products(search: true), .coupons(search: true):
            SearchResultItemActionHandler(posModel: posModel, searchTerm: searchTerm, itemListType: itemListType)
        }
    }

    @ViewBuilder
    func childListView(parentItem: POSItem) -> some View {
        // Note that navigation is handled by the ItemList in iOS 17, so any changes to this should be reflected in ItemListRow.
        switch parentItem {
        case let .variableParentProduct(parentProduct):
            ChildItemList(
                parentItem: parentItem,
                title: parentProduct.name,
                itemsController: itemsController(selectedItemListType),
                itemActionHandler: actionHandler(selectedItemListType)
            )
        default:
            EmptyView()
        }
    }
}

/// Header view
///
@available(iOS 17.0, *)
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            POSPageHeaderView(items: headerViewItems, trailingContent: {
                HStack {
                    if isSearchAllowed {
                        if isSearching {
                            POSSearchField(
                                searchTerm: $searchTerm,
                                searchable: POSProductSearchable(itemListType: selectedItemListType,
                                                                 itemsController: searchItemsController,
                                                                 searchHistoryProvider: posModel.searchHistoryService),
                                onBack: {
                                    withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                                        switch selectedItemListType {
                                        case .products:
                                            selectedItemListType = .products(search: false)
                                        case .coupons:
                                            selectedItemListType = .coupons(search: false)
                                        }
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        } else {
                            POSPageHeaderActionButton(systemName: "magnifyingglass") {
                                withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                                    ServiceLocator.analytics.track(event: WooAnalyticsEvent.PointOfSale.searchButtonTapped(
                                        itemListType: selectedItemListType))
                                    switch selectedItemListType {
                                    case .products:
                                        selectedItemListType = .products(search: true)
                                    case .coupons:
                                        selectedItemListType = .coupons(search: true)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
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
        .animation(.easeInOut(duration: Constants.animationDuration), value: isSearching)
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
                    displayItemListType(.products(search: false))
                }
            )
        ]

        if isCouponsFeatureEnabled {
            items.append(
                POSPageHeaderItem(
                    title: Localization.couponsTitle,
                    isSelected: selectedItemListType.isCoupons,
                    action: {
                        displayItemListType(.coupons(search: false))
                    }
                )
            )
        }

        return items
    }
}

/// View Helpers
///
@available(iOS 17.0, *)
private extension ItemListView {
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
        // Clear search term when switching tabs
        searchTerm = ""
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
        case .coupons(search: false):
            posModel.couponsController
        case .coupons(search: true):
            posModel.couponsSearchController
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
