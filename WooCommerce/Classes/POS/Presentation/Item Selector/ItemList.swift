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

    let state: ItemListState
    let itemsStack: ItemsStackState
    private let node: ItemListBaseItem
    private let headerView: HeaderView

    init(state: ItemListState,
         itemsStack: ItemsStackState,
         node: ItemListBaseItem,
         @ViewBuilder headerView: () -> HeaderView = { EmptyView() }) {
        self.state = state
        self.itemsStack = itemsStack
        self.node = node
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
                    await posModel.loadNextItems(base: node)
                },
                content: {
                    LazyVStack(spacing: Constants.itemSpacing) {
                        headerView

                        ForEach(state.items) { item in
                            ItemListRow(item: item, itemsStack: itemsStack, activeNavigationItem: $activeNavigationItem)
                        }

                        footerRows
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Constants.itemListPadding)
                    .padding(.bottom, floatingControlAreaSize.height)
                }
            )

            // Programmatic navigation overlay for iOS 17
            if #available(iOS 18.0, *) {
                EmptyView()
            } else if let activeItem = activeNavigationItem,
               case let .variableParentProduct(parentProduct) = activeItem {
                NavigationLink(
                    destination: ChildItemList(parentItem: activeItem, title: parentProduct.name, itemsStack: itemsStack),
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
        case .inlineError(_, let errorState):
            ItemListErrorCardView(errorState: errorState,
                                  buttonAction: {
                Task { @MainActor in
                    await posModel.loadNextItems(base: node)
                }
            })
        case .loaded, .error, .empty:
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
    let itemsStack: ItemsStackState
    @Binding var activeNavigationItem: POSItem?
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    let analytics: Analytics = ServiceLocator.analytics

    var body: some View {
        switch item {
        case let .simpleProduct(product):
            Button(action: {
                posModel.addToCart(item)
                analytics.track(event: .PointOfSale.addItemToCart(type: .simpleProduct))
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
                posModel.addToCart(item)
                analytics.track(event: .PointOfSale.addItemToCart(type: .variation))
            }, label: {
                VariationCardView(variation: variation)
            })
        case let .coupon(coupon):
            Button(action: {
                posModel.addToCart(item)
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
        state: itemList,
        itemsStack: .init(root: itemList, itemStates: [:]),
        node: .root(.products)
    )
}

@available(iOS 17.0, *)
#Preview("Loading") {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        couponsController: PointOfSalePreviewCouponsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    ItemList(state: .loading([]),
             itemsStack: .init(root: .loading([]), itemStates: [:]),
             node: .root(.products))
        .environment(posModel)
}

#endif
