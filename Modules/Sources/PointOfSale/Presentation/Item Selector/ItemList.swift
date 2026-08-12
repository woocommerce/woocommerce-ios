import SwiftUI
import enum Yosemite.POSItem

/// Displays a list of POS items or placeholder card based on the given state.
struct ItemList<HeaderView: View>: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.keyboardObserver) private var keyboardObserver
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

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
                            ItemListRow(item: item, position: index, itemActionHandler: itemActionHandler)
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

    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posLayoutScale) private var layoutScale

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
            NavigationLink(value: item) {
                ParentProductCardView(name: parentProduct.name,
                                      imageSource: parentProduct.productImageSource,
                                      detailText: Localization.variationsAvailable)
            }
            .accessibilityIdentifier("pos-variable-product-card-\(parentProduct.productID)")
            .simultaneousGesture(TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
        case let .variation(variation):
            Button(action: {
                itemActionHandler.handleTap(item, position: position)
            }, label: {
                VariationCardView(variation: variation)
            })
            .accessibilityIdentifier("pos-variation-card-\(variation.productVariationID)")
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
                CouponCardView(coupon: coupon,
                               isApplied: ItemListViewHelper().shouldShowAppliedCouponIndicator(coupon: coupon,
                                                                                                cartCoupons: posModel.cart.coupons,
                                                                                                layoutScale: layoutScale))
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
    .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#Preview("Loading") {
    ItemList(itemsController: PointOfSalePreviewItemsController(),
             node: .root,
             itemActionHandler: PointOfSalePreviewItemActionHandler())
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

#endif
