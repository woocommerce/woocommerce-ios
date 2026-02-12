import SwiftUI
import enum Yosemite.POSItem
import struct Yosemite.POSVariableParentProduct

/// Displays a list of POS items or placeholder card based on the given state.
struct ItemList<HeaderView: View>: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.keyboardObserver) private var keyboardObserver
    @Environment(\.posAnalytics) private var analytics
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    // Navigation only uses this on iOS 17
    @State private var activeNavigationItem: POSItem? = nil

    var state: ItemListState? {
        switch node {
        case .root:
            itemsController.itemsViewState.itemsStack.root
        case .parent(let posItem):
            itemsController.itemsViewState.itemsStack.itemStates[posItem]
        }
    }

    private let itemsController: PointOfSaleItemsControllerProtocol
    private let node: ItemListBaseItem
    private let headerView: HeaderView
    private let itemActionHandler: POSItemActionHandler
    private let willLoadMore: (() -> Void)?

    init(itemsController: PointOfSaleItemsControllerProtocol,
         node: ItemListBaseItem,
         itemActionHandler: POSItemActionHandler,
         willLoadMore: (() -> Void)? = nil,
         @ViewBuilder headerView: () -> HeaderView = { EmptyView() }) {
        self.itemsController = itemsController
        self.node = node
        self.itemActionHandler = itemActionHandler
        self.willLoadMore = willLoadMore
        self.headerView = headerView()
    }

    var body: some View {
        ZStack {
            InfiniteScrollView(
                triggerDeterminer: infiniteScrollTriggerDeterminer,
                loadMore: {
                    guard case .loaded(_, let hasMoreItems) = state,
                          hasMoreItems
                    else { return }
                    willLoadMore?()
                    await itemsController.loadNextItems(base: node)
                },
                content: {
                    LazyVStack(spacing: Constants.itemSpacing) {
                        headerView

                        headerRows

                        if let state {
                            ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                                ItemListRow(item: item, position: index, itemActionHandler: itemActionHandler, activeNavigationItem: $activeNavigationItem)
                            }
                        }

                        footerRows
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Constants.itemListPadding)
                    .padding(.bottom, keyboardObserver.isFullSizeKeyboardVisible ? Constants.itemListPadding : floatingControlAreaSize.height)
                    .animation(.default, value: state?.items)
                }
            )

            // Programmatic navigation overlay for iOS 17
            if #available(iOS 18.0, *) {
                EmptyView()
            } else if let activeItem = activeNavigationItem,
               case let .variableParentProduct(parentProduct) = activeItem {
                // This always uses the non-search itemsController, otherwise it will have the search term and not work properly
                // This is a temporary fix until we tidy up the stack selection, as it means non-products child lists won't work.
                NavigationLink(
                    destination: ChildItemList(parentItem: activeItem,
                                               title: parentProduct.name,
                                               itemsController: posModel.purchasableItemsController,
                                               itemActionHandler: itemActionHandler,
                                               analyticsTracker: PointOfSaleItemListAnalyticsTracker(
                                                sourceView: .variation,
                                                sourceViewType: .init(
                                                    isSearching: posModel.viewStateCoordinatorForView.selectedItemListType.isSearching,
                                                    searchTerm: posModel.viewStateCoordinatorForView.searchTerm
                                                ),
                                                analytics: analytics
                                               ))
                    .barcodeScanning { scannedCode in
                        posModel.barcodeScanned(scannedCode)
                    },
                    isActive: Binding(
                        get: { activeNavigationItem != nil },
                        set: { if !$0 { activeNavigationItem = nil } }
                    ),
                    label: { EmptyView() })
                .opacity(0)
                .frame(width: 0, height: 0)
            }
        }
    }

    @ViewBuilder var footerRows: some View {
        switch state {
        case .loading(let items):
            if items.isEmpty {
                ForEach(0..<8) { _ in
                    GhostItemCardView()
                }
            } else {
                GhostItemCardView()
            }
        case .inlineError(_, let errorState, .pagination):
            POSListInlineErrorView(errorState: errorState,
                                  buttonAction: {
                await itemsController.loadNextItems(base: node)
            })
        case .initial, .loaded, .error, .empty, .none, .inlineError(_, _, .refresh):
            EmptyView()
        }
    }

    @ViewBuilder var headerRows: some View {
        switch state {
        case .inlineError(_, let errorState, .refresh):
            POSListInlineErrorView(errorState: errorState,
                                  buttonAction: {
                await itemsController.loadItems(base: .root)
            })
        case .initial, .loaded, .error, .empty, .none, .loading, .inlineError(_, _, .pagination):
            EmptyView()
        }
    }
}

private enum Constants {
    static let itemListPadding: CGFloat = POSPadding.medium
    static let itemSpacing: CGFloat = POSSpacing.medium
}

struct ItemListRow: View {
    let item: POSItem
    let position: Int
    let itemActionHandler: POSItemActionHandler
    @Binding var activeNavigationItem: POSItem?

    var body: some View {
        switch item {
        case let .simpleProduct(product):
            Button(action: {
                itemActionHandler.handleTap(item, position: position)
            }, label: {
                SimpleProductCardView(product: product)
            })
            .accessibilityIdentifier("pos-product-card-\(product.productID)")
        case let .variableParentProduct(parentProduct):
            if #available(iOS 18.0, *) {
                NavigationLink(value: item) {
                    ParentProductCardView(name: parentProduct.name,
                                          imageSource: parentProduct.productImageSource,
                                          detailText: Localization.variationsAvailable)
                }
            } else {
                // Use a button to trigger navigation programmatically on iOS 17.

                // We should drop this when we leave iOS 17.0 behind, but due to memory leaks caused by NavigationStack.
                // we still have to use the NavigationView approach here.
                // When we remove it, itemsStack will no longer be a dependency of ItemList

                // Note that we don't use Navigation Link as this row can be redrawn if the dynamic type size
                // is changed enough to push it offscreen. When that happens while viewing a child list,
                // the navigation gets cancelled and the user is sent back to the root.
                Button(action: {
                    activeNavigationItem = item
                }, label: {
                    ParentProductCardView(name: parentProduct.name,
                                          imageSource: parentProduct.productImageSource,
                                          detailText: Localization.variationsAvailable)
                })
            }
        case let .variation(variation):
            Button(action: {
                itemActionHandler.handleTap(item, position: position)
            }, label: {
                VariationCardView(variation: variation)
            })
        case let .searchResultVariation(variation, parentProduct):
            Button(action: {
                itemActionHandler.handleTap(item, position: position)
            }, label: {
                SearchResultVariationCardView(variation: variation, parentProduct: parentProduct)
            })
            .accessibilityIdentifier("pos-search-variation-card-\(variation.productVariationID)")
        case let .coupon(coupon):
            Button(action: {
                if !coupon.isExpired {
                    itemActionHandler.handleTap(item, position: position)
                }
            }, label: {
                CouponCardView(coupon: coupon)
            })
        }
    }
}

private extension ItemListRow {
    enum Localization {
        static let variationsAvailable = NSLocalizedString(
            "pos.parentProductCard.optionsAvailable",
            value: "Options available",
            comment: "Text indicating that there are options available for a parent product"
        )
    }
}

#if DEBUG
#Preview("Loaded with items") {
    ItemList(
        itemsController: PointOfSalePreviewItemsController(),
        node: .root,
        itemActionHandler: PointOfSalePreviewItemActionHandler()
    )
}

#Preview("Loading") {
    ItemList(itemsController: PointOfSalePreviewItemsController(),
             node: .root,
             itemActionHandler: PointOfSalePreviewItemActionHandler())
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
