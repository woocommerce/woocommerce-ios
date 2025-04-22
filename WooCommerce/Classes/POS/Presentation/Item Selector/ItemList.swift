import SwiftUI
import enum Yosemite.POSItem
import protocol WooFoundation.Analytics
import struct Yosemite.POSVariableParentProduct

/// Displays a list of POS items or placeholder card based on the given state.
@available(iOS 17.0, *)
struct ItemList<HeaderView: View>: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    // Navigation only uses this on iOS 17
    @State private var activeNavigationItem: POSItem? = nil
    @State private var scrollPositions: [ItemListType: CGFloat] = [:]
    @State private var currentPosition: CGFloat = 0

    var state: ItemListState? {
        switch node {
        case .root:
            itemsController.itemsViewState.itemsStack.root
        case .parent(let posItem):
            itemsController.itemsViewState.itemsStack.itemStates[posItem]
        }
    }

    private var scrollPositionKey: ItemListType {
        switch itemsController {
        case is PointOfSaleItemsController:
            return .products()
        default:
            return .coupons
        }
    }

    private let itemsController: PointOfSaleItemsControllerProtocol
    private let node: ItemListBaseItem
    private let headerView: HeaderView
    private let itemActionHandler: POSItemActionHandler

    init(itemsController: PointOfSaleItemsControllerProtocol,
         node: ItemListBaseItem,
         itemActionHandler: POSItemActionHandler,
         @ViewBuilder headerView: () -> HeaderView = { EmptyView() }) {
        self.itemsController = itemsController
        self.node = node
        self.itemActionHandler = itemActionHandler
        self.headerView = headerView()
    }

    var body: some View {
        ZStack {
            ScrollViewReader { scrollViewProxy in
                InfiniteScrollView(
                    triggerDeterminer: infiniteScrollTriggerDeterminer,
                    currentPosition: $currentPosition,
                    loadMore: {
                        guard case .loaded(_, let hasMoreItems) = state,
                              hasMoreItems
                        else { return }
                        await itemsController.loadNextItems(base: node)
                    },
                    content: {
                        LazyVStack(spacing: Constants.itemSpacing) {
                            headerView

                            headerRows

                            if let state {
                                ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                                    ItemListRow(item: item, itemActionHandler: itemActionHandler, activeNavigationItem: $activeNavigationItem)
                                        .id("\(scrollPositionKey)-\(index)")
                                }
                            }

                            footerRows
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Constants.itemListPadding)
                        .padding(.bottom, floatingControlAreaSize.height)
                        .onChange(of: scrollPositionKey) { previousScrollPositionKey, newScrollPositionKey in
                            // Saves old key's position, and restore position for new key, if any:
                            scrollPositions[previousScrollPositionKey] = currentPosition

                            if let savedPosition = scrollPositions[newScrollPositionKey], let state = state {
                                // Updates position for this key, then scrolls to saved position
                                currentPosition = savedPosition

                                let itemHeight: CGFloat = PointOfSaleItemListCardConstants.productCardSize
                                let targetIndex = Int(savedPosition / itemHeight)
                                let safeIndex = min(targetIndex, (state.items.count) - 1)
                                scrollViewProxy.scrollTo("\(newScrollPositionKey)-\(safeIndex)", anchor: .top)
                            } else {
                                // First time seeing this key, set to top position
                                currentPosition = 0
                                scrollViewProxy.scrollTo("\(newScrollPositionKey)-0", anchor: .top)
                            }
                        }
                    }
                )
            }

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
                                               itemActionHandler: itemActionHandler),
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
            ItemListErrorCardView(errorState: errorState,
                                  buttonAction: {
                Task { @MainActor in
                    await itemsController.loadNextItems(base: node)
                }
            })
        case .loaded, .error, .empty, .none, .inlineError(_, _, .refresh):
            EmptyView()
        }
    }

    @ViewBuilder var headerRows: some View {
        switch state {
        case .inlineError(_, let errorState, .refresh):
            ItemListErrorCardView(errorState: errorState,
                                  buttonAction: {
                Task { @MainActor in
                    await itemsController.loadItems(base: .root)
                }
            })
        case .loaded, .error, .empty, .none, .loading, .inlineError(_, _, .pagination):
            EmptyView()
        }
    }
}

private enum Constants {
    static let itemListPadding: CGFloat = POSPadding.medium
    static let itemSpacing: CGFloat = POSSpacing.small
}

@available(iOS 17.0, *)
private struct ItemListRow: View {
    let item: POSItem
    let itemActionHandler: POSItemActionHandler
    @Binding var activeNavigationItem: POSItem?
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    let analytics: Analytics = ServiceLocator.analytics

    var body: some View {
        switch item {
        case let .simpleProduct(product):
            Button(action: {
                itemActionHandler.handleTap(item)
            }, label: {
                SimpleProductCardView(product: product)
            })
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
                itemActionHandler.handleTap(item)
            }, label: {
                VariationCardView(variation: variation)
            })
        case let .coupon(coupon):
            Button(action: {
                itemActionHandler.handleTap(item)
            }, label: {
                CouponCardView(coupon: coupon)
            })
        }
    }
}

@available(iOS 17.0, *)
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
@available(iOS 17.0, *)
#Preview("Loaded with items") {
    let itemList: ItemListState = .loaded(
        [
            .simpleProduct(
                .init(
                    id: .init(),
                    name: "Strong latte 16oz",
                    formattedPrice: "$4.00",
                    productID: 12,
                    price: "4.00"
                )
            ),
            .variableParentProduct(
                .init(
                    id: .init(),
                    name: "Variable mocha",
                    productImageSource: "https://pd.w.org/2024/12/986762d0d4d4cf17.82435881-scaled.jpeg",
                    productID: 16
                )
            )
        ],
        hasMoreItems: false
    )
    ItemList(
        itemsController: PointOfSalePreviewItemsController(),
        node: .root,
        itemActionHandler: PointOfSalePreviewItemActionHandler()
    )
}

@available(iOS 17.0, *)
#Preview("Loading") {
    ItemList(itemsController: PointOfSalePreviewItemsController(),
             node: .root,
             itemActionHandler: PointOfSalePreviewItemActionHandler())
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
