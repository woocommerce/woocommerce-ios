import SwiftUI
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

@available(iOS 17.0, *)
struct ItemListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(PointOfSaleAggregateModel.self) private var posModel

    @State private var showSimpleProductsModal: Bool = false

    @Binding var selectedItemListType: ItemListType
    @Binding var searchTerm: String

    private var shouldShowSearchField: Bool {
        selectedItemListType == .products(search: true)
    }
    @FocusState private var isSearchFieldFocused: Bool

    @State private var searchTask: Task<Void, Never>?
    @State private var didFinishSearch = true

    var itemsController: PointOfSaleItemsControllerProtocol {
        switch selectedItemListType {
        case .products(search: false):
            posModel.purchasableItemsController
        case .products(search: true):
            posModel.purchasableItemsSearchController
        case .coupons:
            posModel.couponsController
        }
    }

    private var itemListState: ItemListState {
        itemsController.itemsViewState.itemsStack.root
    }

    @AppStorage(BannerState.isSimpleProductsOnlyBannerDismissedKey)
    private var isHeaderBannerDismissed: Bool = false

    private var shouldShowCoupons: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale)
    }

    private var isAddingCouponAllowed: Bool {
        guard case .coupons = selectedItemListType else { return false }
        return itemListState.isLoaded || itemListState.isEmpty
    }

    private var isSearchAllowed: Bool {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.searchProductsInPOS) else {
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
        !shouldShowSearchField
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

            if shouldShowSearchField && searchTerm.isEmpty {
                POSRecentSearchesView(
                    savedSearches: posModel.searchHistory(for: selectedItemListType.itemType),
                    onSearchSelected: { search in
                        searchTerm = search
                    }
                )
                .background(Color.posSurface)
            } else {
                switch itemListState {
                case .loading(let items),
                        .loaded(let items, _),
                        .inlineError(let items, _, _):
                    listView(items)
                case .error(let errorState):
                    errorView(errorState)
                case .empty:
                    emptyView
                }
            }
        }
        // N.B. This navigationDestination causes a runtime warning in iOS 17, and is ignored. On iOS 17,
        // the navigation is handled in a NavigationLink in ItemList.swift. Avoiding the warning is impractical.
        .navigationDestination(for: POSItem.self, destination: { item in
            childListView(parentItem: item)
        })
        .background(Color.posSurface)
        .accessibilityElement(children: .contain)
        .posModal(isPresented: $showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $showSimpleProductsModal)
        }
        .posCouponCreationSheet(isPresented: $showCouponCreationModal, onSuccess: { couponItem in
            Task { @MainActor in
                posModel.addToCart(couponItem)
                await posModel.couponsController.refreshItems(base: .root)
            }
        })
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
                            .renderedIf(shouldShowSearchField)
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
                                selectedItemListType = .products(search: true)
                            } completion: {
                                isSearchFieldFocused = true
                            }
                        }
                        .renderedIf(!shouldShowSearchField)
                        .transition(.opacity.combined(with: .scale))
                    }

                    if shouldShowCoupons {
                        POSPageHeaderActionButton(systemName: "plus") {
                            ServiceLocator.analytics.track(.pointOfSaleCouponsCreateTapped)
                            showCouponCreationModal = true
                        }
                        .renderedIf(isAddingCouponAllowed)
                        .transition(.opacity.combined(with: .scale))
                    }

                    Button(action: {
                        ServiceLocator.analytics.track(.pointOfSaleSimpleProductsExplanationDialogShown)
                        showSimpleProductsModal = true
                    }, label: {
                        Text(Image(systemName: "info.circle"))
                            .font(.posButtonSymbolLarge)
                            .foregroundStyle(Color.posOnSurface)
                            .padding(Constants.infoIconInset)
                    })
                    .renderedIf(!shouldShowHeaderBanner && !shouldShowCoupons)
                    .transition(.opacity.combined(with: .scale))
                }
            })
            if !dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                bannerCardView
                    .padding(.horizontal, Constants.bannerCardPadding)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: Constants.animationDuration), value: shouldShowSearchField)
        .animation(.easeInOut(duration: Constants.animationDuration), value: shouldShowHeaderBanner)
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

        if shouldShowCoupons {
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
    }

    var bannerCardView: some View {
        POSNoticeView(
            title: headerBannerTitle,
            icon: Image(systemName: "info.circle"),
            onDismiss: {
                isHeaderBannerDismissed = true
            },
            onTap: {
                showSimpleProductsModal = true
            }
        ) {
            VStack(alignment: .leading, spacing: Constants.bannerTextSpacing) {
                Text(headerBannerSubtitle)
                bannerHintAndLearnMoreText
            }
        }
        .padding(.bottom, Constants.bannerCardPadding)
    }

    private var bannerHintAndLearnMoreText: some View {
        Text("\(headerBannerHint) \(Localization.headerBannerLearnMoreHint)")
            .font(.posBodySmallBold)
            .foregroundColor(Color(.posPrimary))
    }

    @ViewBuilder
    func listView(_ items: [POSItem]) -> some View {
        ItemList(
            itemsController: itemsController,
            node: .root,
            itemActionHandler: actionHandler
        ) {
            if dynamicTypeSize.isAccessibilitySize, shouldShowHeaderBanner {
                bannerCardView
            }
        }
        .refreshable {
            trackPullToRefresh()
            await itemsController.refreshItems(base: .root)
        }
    }

    private var actionHandler: POSItemActionHandler {
        switch selectedItemListType {
        case .products(search: false), .coupons:
            StandardPOSItemActionHandler(posModel: posModel)
        case .products(search: true):
            SearchResultItemActionHandler(posModel: posModel, searchTerm: searchTerm, itemListType: selectedItemListType)
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
                itemActionHandler: actionHandler
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
                    await itemsController.loadItems(base: .root)
                }
            })
        }
    }
}

@available(iOS 17.0, *)
private extension ItemListView {
    var shouldShowHeaderBanner: Bool {
        guard case .products = selectedItemListType else {
            return false
        }

        return itemListState.eligibleToShowSimpleProductsBanner && !isHeaderBannerDismissed
    }

    func displayItemListType(_ itemListType: ItemListType) {
        selectedItemListType = itemListType
        Task { @MainActor in
            if itemListState.items.isEmpty {
                await itemsController.loadItems(base: .root)
            }
        }

        trackSelectedItemListTypeTapped(itemListType)
    }
}

private extension ItemListState {
    var eligibleToShowSimpleProductsBanner: Bool {
        switch self {
        case .loading,
                .loaded,
                .inlineError:
            return true
        case .error, .empty:
            return false
        }
    }
}

/// Constants
///
@available(iOS 17.0, *)
private extension ItemListView {
    enum Constants {
        static let infoIconInset: EdgeInsets = .init(top: 0, leading: 6, bottom: 0, trailing: 6)
        static let bannerCardPadding: CGFloat = POSPadding.medium
        static let bannerTextSpacing: CGFloat = POSSpacing.xSmall
        static let animationDuration: CGFloat = 0.2
    }

    enum BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }

    var headerBannerTitle: String {
        Localization.headerBannerTitleSimpleAndVariable
    }

    var headerBannerSubtitle: String {
        Localization.headerBannerSubtitleSimpleAndVariable
    }

    var headerBannerHint: String {
        Localization.headerBannerHintSimpleAndVariable
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

        static let headerBannerTitleSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.title.simpleAndVariable",
            value: "Showing simple and variable products only",
            comment: "Title of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerSubtitleSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.subtitle.simpleAndVariable",
            value: "Only simple and variable non-downloadable products can be used with POS right now.",
            comment: "Subtitle of the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerHintSimpleAndVariable = NSLocalizedString(
            "pos.itemlistview.headerBanner.hint.simpleAndVariable",
            value: "Other product types will become available in future updates.",
            comment: "Additional text within the product selector header banner, which explains current POS limitations"
        )

        static let headerBannerLearnMoreHint = NSLocalizedString(
            "pos.itemlistview.headerBanner.learnMoreHint",
            value: "Learn More",
            comment: "Link to more information within the product selector header banner, which explains current POS limitations"
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
