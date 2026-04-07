import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import struct WooFoundationCore.WooAnalyticsEvent

struct ItemListView: View {
    @Environment(\.posAnalytics) private var analytics
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @EnvironmentObject var modalManager: POSModalManager
    @EnvironmentObject var sheetManager: POSSheetManager
    @EnvironmentObject var coverManager: POSFullScreenCoverManager

    @Binding var selectedItemListType: ItemListType
    @Binding var searchTerm: String

    private var analyticsTracker: PointOfSaleItemListAnalyticsTracker {
        PointOfSaleItemListAnalyticsTracker(
            selectedItemListType: selectedItemListType,
            searchTerm: searchTerm,
            analytics: analytics
        )
    }

    private var _isSearching: Binding<Bool> {
        Binding(
            get: {
                switch selectedItemListType {
                case let .products(search), let .coupons(search):
                    return search
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

    private var isBarcodeScanningEnabled: Binding<Bool> {
        Binding(
            get: { !isSearching && !modalManager.isPresented && !sheetManager.isPresented && !coverManager.isPresented },
            set: { _ in }
        )
    }

    private var isAddingCouponAllowed: Bool {
        guard case .coupons = selectedItemListType else { return false }
        let itemListState = itemListState(selectedItemListType)
        return itemListState.isLoaded || itemListState.isEmpty
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

            ZStack {
                itemListTabContent(.products(search: false))
                    .opacity(selectedItemListType.isProducts ? 1 : 0)
                    .accessibilityHidden(!selectedItemListType.isProducts)
                itemListTabContent(.coupons(search: false))
                    .opacity(selectedItemListType.isCoupons ? 1 : 0)
                    .accessibilityHidden(!selectedItemListType.isCoupons)
            }
            .ignoresSafeArea(.container)
        }
        // N.B. This navigationDestination causes a runtime warning in iOS 17, and is ignored. On iOS 17,
        // the navigation is handled in a NavigationLink in ItemList.swift. Avoiding the warning is impractical.
        .navigationDestination(for: POSItem.self, destination: { item in
            childListView(parentItem: item)
        })
        .background(Color.posSurface)
        .accessibilityElement(children: .contain)
        .posCouponCreationSheet(isPresented: $showCouponCreationModal,
                                currencySettings: currencyProvider.currencySettings,
                                onSuccess: { couponItem in
            Task { @MainActor in
                posModel.addToCart(couponItem)
                await posModel.couponsController.refreshItems(base: .root)
            }
        })
        .barcodeScanning(enabled: isBarcodeScanningEnabled) { scannedCode in
            posModel.barcodeScanned(scannedCode)
        }
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
                .ignoresSafeArea(.keyboard)
                .accessibilityElement(children: isSearching ? .ignore : .contain)

            if isSearching {
                POSSearchContentView(
                    searchable: POSProductSearchable(itemListType: selectedItemListType,
                                                     itemsController: searchItemsController,
                                                     searchHistoryProvider: posModel.searchHistoryService),
                    itemListType: selectedItemListType,
                    searchTerm: $searchTerm
                ) { _ in
                    itemListContent(selectedItemListType)
                }
                .scrollDismissesKeyboard(.immediately)
                .zIndex(1)
            }
        }
        .allowsHitTesting(selectedItemListType == itemListType)
    }

    @ViewBuilder
    private func itemListContent(_ itemListType: ItemListType) -> some View {
        switch itemListState(itemListType) {
        case .initial,
                .loading,
                .loaded,
                .inlineError:
            listView(itemListType: itemListType)
        case .error(let errorState):
            errorView(errorState)
        case .empty:
            emptyView
        }
    }

    @ViewBuilder
    private func listView(itemListType: ItemListType) -> some View {
        VStack(spacing: 0) {
            // Stale sync warning banner
            if posModel.showStaleSyncWarning {
                staleSyncWarningBanner
                    .padding(.horizontal, POSPadding.medium)
                    .padding(.vertical, POSPadding.small)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ItemList(
                itemsController: itemsController(itemListType),
                node: .root,
                itemActionHandler: actionHandler(itemListType),
                willLoadMore: {
                    analyticsTracker.trackNextPageWillLoad()
                }
            )
            .refreshable {
                analyticsTracker.trackRefresh()
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await itemsController(itemListType).refreshItems(base: .root)
                    }
                    group.addTask {
                        await posModel.popularPurchasableItemsController.refreshItems(base: .root)
                    }
                    // Trigger incremental sync on pull to refresh when the items controller uses local catalog
                    // The additional itemListType check avoids duplicated sync on products list (non-search)
                    if itemListType == .products(search: true) && posModel.isLocalCatalogEligible {
                        group.addTask {
                            await posModel.purchasableItemsController.refreshItems(base: .root)
                        }
                    }
                }
            }
        }
        .task {
            // Check stale sync status when view appears
            await posModel.checkStaleSyncStatus()
        }
    }

    @ViewBuilder
    private var staleSyncWarningBanner: some View {
        POSNoticeView(
            title: Localization.staleSyncWarningTitle,
            icon: Image(systemName: "info.circle"),
            onDismiss: {
                analytics.track(event: WooAnalyticsEvent.LocalCatalog.staleWarningDismissed())
                withAnimation {
                    posModel.dismissStaleSyncWarning()
                }
            }, content: {
                Text(Localization.staleSyncWarningDescription(days: posModel.staleSyncThresholdDays))
                    .font(POSFontStyle.posBodyMediumRegular())
            })
            .task {
                // Track stale warning shown with hours since last sync
                if let hours = await posModel.hoursSinceLastSync() {
                    analytics.track(event: WooAnalyticsEvent.LocalCatalog.staleWarningShown(hoursSinceLastSync: hours))
                }
            }
    }

    private func actionHandler(_ itemListType: ItemListType) -> POSItemActionHandler {
        POSItemActionHandlerFactory.itemActionHandler(
            itemListType: itemListType,
            searchTerm: searchTerm,
            posModel: posModel,
            analytics: analytics
        )
    }

    private func variationActionHandler(_ itemListType: ItemListType) -> POSItemActionHandler {
        POSItemActionHandlerFactory.variationActionHandler(
            itemListType: itemListType,
            searchTerm: searchTerm,
            posModel: posModel,
            analytics: analytics
        )
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
                itemActionHandler: variationActionHandler(selectedItemListType),
                analyticsTracker: PointOfSaleItemListAnalyticsTracker(
                    sourceView: .variation,
                    sourceViewType: .init(isSearching: selectedItemListType.isSearching, searchTerm: searchTerm),
                    analytics: analytics
                )
            )
            .barcodeScanning(enabled: isBarcodeScanningEnabled) { scannedCode in
                posModel.barcodeScanned(scannedCode)
            }
        default:
            EmptyView()
        }
    }
}

/// Header view
///
private extension ItemListView {
    @ViewBuilder
    var headerView: some View {
        VStack {
            POSPageHeaderView(items: headerViewItems, trailingContent: {
                HStack {
                    if isSearching {
                        POSSearchField(
                            searchTerm: $searchTerm,
                            searchable: POSProductSearchable(itemListType: selectedItemListType,
                                                             itemsController: searchItemsController,
                                                             searchHistoryProvider: posModel.searchHistoryService),
                            onBack: {
                                setSearch(false)
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    } else {
                        createCouponButton

                        POSPageHeaderActionButton(systemName: "magnifyingglass") {
                            analyticsTracker.trackSearchTapped(itemListType: selectedItemListType)
                            setSearch(true)
                        }
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

        items.append(
            POSPageHeaderItem(
                title: Localization.couponsTitle,
                isSelected: selectedItemListType.isCoupons,
                action: {
                    displayItemListType(.coupons(search: false))
                }
            )
        )

        return items
    }
}

/// View Helpers
///
private extension ItemListView {
    @ViewBuilder
    private var createCouponButton: some View {
        POSPageHeaderActionButton(systemName: "plus") {
            analytics.track(.pointOfSaleCouponsCreateTapped)
            showCouponCreationModal = true
        }
        .renderedIf(isAddingCouponAllowed)
        .transition(.opacity.combined(with: .scale))
    }

    @ViewBuilder
    var emptyView: some View {
        switch selectedItemListType {
        case .products:
            POSListEmptyView(
                viewModel: POSListEmptyViewModel(
                    itemListType: selectedItemListType,
                    baseItem: .root)) {
                Task {
                    await itemsController(selectedItemListType).loadItems(base: .root)
                }
            }
        case .coupons:
            POSListEmptyView(
                viewModel: POSListEmptyViewModel(
                    itemListType: selectedItemListType,
                    baseItem: .root)) {
                showCouponCreationModal = true
            }
        }
    }

    @ViewBuilder
    func errorView(_ errorState: PointOfSaleErrorState) -> some View {
        switch errorState.errorType {
        case .couponsDisabled:
            POSListErrorView(error: errorState, onAction: {
                Task {
                    await posModel.couponsController.enableCoupons()
                    analytics.track(.couponSettingEnabled)
                }
            })
        default:
            POSListErrorView(error: errorState, onAction: {
                Task {
                    await itemsController(selectedItemListType).loadItems(base: .root)
                }
            })
        }
    }
}

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

        analyticsTracker.trackItemListSelected(itemListType: itemListType)
    }
}

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

    private func setSearch(_ isSearching: Bool) {
        switch selectedItemListType {
        case .products:
            selectedItemListType = .products(search: isSearching)
        case .coupons:
            selectedItemListType = .coupons(search: isSearching)
        }
    }
}

/// Constants
///
private extension ItemListView {
    enum Constants {
        static let animationDuration: CGFloat = 0.2
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

        static let staleSyncWarningTitle = NSLocalizedString(
            "pos.itemlistview.staleSyncWarning.title",
            value: "Refresh catalog",
            comment: "Warning title shown when the product catalog hasn't synced in several days"
        )

        static let staleSyncWarningDescriptionFormat = NSLocalizedString(
            "pos.itemlistview.staleSyncWarning.description",
            value: "The catalog hasn't been synced in the last %1$ld days. Please ensure you're connected to the internet and sync again in POS Settings.",
            comment: "Message shown when the product catalog hasn't synced in the specified number of days. " +
            "%1$ld will be replaced with the number of days. Reads like: The catalog hasn't been synced in the last 7 days."
        )

        static func staleSyncWarningDescription(days: Int) -> String {
            String.localizedStringWithFormat(staleSyncWarningDescriptionFormat, days)
        }
    }
}

#if DEBUG

#Preview("Loaded with all product types") {
    let itemsController = PointOfSalePreviewItemsController()
    Task { @MainActor in
        await itemsController.loadItems(base: .root)
    }
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(itemsController: itemsController)
    return ItemListView(selectedItemListType: .constant(.products(search: false)),
                        searchTerm: .constant(""))
        .environment(posModel)
        .environmentObject(POSModalManager())
        .environmentObject(POSSheetManager())
}

#Preview("Loading") {
    ItemListView(selectedItemListType: .constant(.products(search: false)),
                 searchTerm: .constant(""))
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
        .environmentObject(POSModalManager())
        .environmentObject(POSSheetManager())
}

#endif
