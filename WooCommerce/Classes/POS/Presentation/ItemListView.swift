import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

@available(iOS 17.0, *)
struct ItemListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.keyboardObserver) private var keyboardObserver
    @EnvironmentObject var modalManager: POSModalManager

    @Binding var selectedItemListType: ItemListType
    @Binding var searchTerm: String

    private var analyticsTracker: PointOfSaleItemListAnalyticsTracker {
        PointOfSaleItemListAnalyticsTracker(selectedItemListType: selectedItemListType, searchTerm: searchTerm)
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
            get: { !isSearching && !modalManager.isPresented },
            set: { _ in }
        )
    }

    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true

    private var isBarcodeScani1FeatureEnabled: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleBarcodeScanningi1)
    }

    private var isBarcodeScanSimulatorEnabled: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.showPointOfSaleBarcodeSimulator)
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

    @State private var barcodeScanSimulatorIsPresented: Bool = false
    @State private var barcodeScanSimulatorText: String = ""

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
                itemListTabContent(.coupons(search: false))
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
                .accessibilityElement(children: isSearching ? .ignore : .contain)

            if isSearching {
                POSSearchContentView(
                    searchable: POSProductSearchable(itemListType: selectedItemListType,
                                                     itemsController: searchItemsController,
                                                     searchHistoryProvider: posModel.searchHistoryService),
                    searchTerm: $searchTerm
                ) { _ in
                    itemListContent(selectedItemListType)
                }
                .scrollDismissesKeyboard(.immediately)
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
                analyticsTracker.trackNextPageWillLoad()
            }
        )
        .refreshable {
            analyticsTracker.trackRefresh()
            await itemsController(itemListType).refreshItems(base: .root)
        }
    }

    private func actionHandler(_ itemListType: ItemListType) -> POSItemActionHandler {
        POSItemActionHandlerFactory.itemActionHandler(
            itemListType: itemListType,
            searchTerm: searchTerm,
            posModel: posModel
        )
    }

    private func variationActionHandler(_ itemListType: ItemListType) -> POSItemActionHandler {
        POSItemActionHandlerFactory.variationActionHandler(
            itemListType: itemListType,
            searchTerm: searchTerm,
            posModel: posModel
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
                    sourceViewType: .init(isSearching: selectedItemListType.isSearching, searchTerm: searchTerm)
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
@available(iOS 17.0, *)
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

                        simulatedScanButton
                            .renderedIf(isBarcodeScanSimulatorEnabled && isBarcodeScani1FeatureEnabled)

                        POSPageHeaderActionButton(systemName: "magnifyingglass") {
                            analyticsTracker.trackSearchTapped(itemListType: selectedItemListType)
                            setSearch(true)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }

                }
            })

            barcodeScanSimulator
                .renderedIf(barcodeScanSimulatorIsPresented)
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
@available(iOS 17.0, *)
private extension ItemListView {
    @ViewBuilder
    private var createCouponButton: some View {
        POSPageHeaderActionButton(systemName: "plus") {
            ServiceLocator.analytics.track(.pointOfSaleCouponsCreateTapped)
            showCouponCreationModal = true
        }
        .renderedIf(isAddingCouponAllowed)
        .transition(.opacity.combined(with: .scale))
    }

    @ViewBuilder
    private var simulatedScanButton: some View {
        POSPageHeaderActionButton(systemName: "barcode") {
            barcodeScanSimulatorIsPresented.toggle()
        }
        .transition(.opacity.combined(with: .scale))
    }

    @ViewBuilder
    private var barcodeScanSimulator: some View {
        HStack {
            TextField(text: $barcodeScanSimulatorText) {
                Text("Barcode value")
            }

            Button {
                posModel.barcodeScanned(.success(barcodeScanSimulatorText))
            } label: {
                Text("Scan!")
            }
            .buttonStyle(POSFilledButtonStyle(size: .extraSmall))
        }
        .padding([.bottom, .horizontal], 16)
    }

    @ViewBuilder
    var emptyView: some View {
        switch selectedItemListType {
        case .products:
            PointOfSaleItemListEmptyView(
                viewModel: PointOfSaleItemListEmptyViewModel(
                    itemListType: selectedItemListType,
                    baseItem: .root)) {
                Task {
                    await itemsController(selectedItemListType).loadItems(base: .root)
                }
            }
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
        switch errorState.errorType {
        case .couponsDisabled:
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

        analyticsTracker.trackItemListSelected(itemListType: itemListType)
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
