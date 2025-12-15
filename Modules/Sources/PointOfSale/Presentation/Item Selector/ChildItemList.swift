import SwiftUI
import Yosemite

/// Displays a scrollable list of child items in POS.
struct ChildItemList: View {
    private let parentItem: POSItem
    private let title: String
    private var itemsController: PointOfSaleItemsControllerProtocol
    private let itemActionHandler: POSItemActionHandler
    private let analyticsTracker: PointOfSaleItemListAnalyticsTracker
    @Environment(\.dismiss) private var dismiss

    private var node: ItemListBaseItem {
        .parent(parentItem)
    }

    private var state: ItemListState {
        itemsController.itemsViewState.itemsStack.itemStates[parentItem] ??
            .loading([])
    }

    init(parentItem: POSItem,
         title: String,
         itemsController: PointOfSaleItemsControllerProtocol,
         itemActionHandler: POSItemActionHandler,
         analyticsTracker: PointOfSaleItemListAnalyticsTracker) {
        self.parentItem = parentItem
        self.title = title
        self.itemsController = itemsController
        self.itemActionHandler = itemActionHandler
        self.analyticsTracker = analyticsTracker
    }

    var body: some View {
        VStack {
            switch state {
            case .initial, .loaded([], _):
                emptyView
            case .loading, .loaded, .inlineError:
                listView
            case let .error(error):
                errorView(error: error)
            case .empty:
                emptyView
            }
        }
        .background(Color.posSurface)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard state.items.isEmpty else {
                return
            }
            await itemsController.loadItems(base: node)
        }
    }
}

private extension ChildItemList {
    @ViewBuilder var headerView: some View {
        POSPageHeaderView(title: title,
                          backButtonConfiguration: .init(state: .enabled,
                                                         action: {
            dismiss()
        }))
    }

    @ViewBuilder
    var listView: some View {
        VStack(spacing: 0) {
            headerView

            ItemList(itemsController: itemsController,
                     node: node,
                     itemActionHandler: itemActionHandler,
                     willLoadMore: {
                analyticsTracker.trackNextPageWillLoad()
            })
            .transition(.opacity)
            .refreshable {
                analyticsTracker.trackRefresh()
                await itemsController.refreshItems(base: node)
            }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        VStack {
            headerView
            POSListEmptyView(
                viewModel: POSListEmptyViewModel(
                    itemListType: .products(search: false),
                    baseItem: node)) {
                Task {
                    await itemsController.loadItems(base: node)
                }
            }
        }
    }

    @ViewBuilder
    func errorView(error: PointOfSaleErrorState) -> some View {
        ZStack {
            VStack {
                headerView
                Spacer()
            }

            POSListErrorView(error: error, onAction: {
                Task {
                    await itemsController.loadItems(base: node)
                }
            })
            .zIndex(1)
        }
    }
}

#if DEBUG

#Preview("Variable product child items") {
    let parentProduct = POSVariableParentProduct(
        id: .init(underlyingType: .product, itemID: 1),
        name: "Variable latte",
        productImageSource: nil,
        productID: 1
    )
    let parentItem = POSItem.variableParentProduct(parentProduct)
    let itemsController = PointOfSalePreviewItemsController()
    let itemsStack = ItemsStackState(
        root: .loading([]),
        itemStates: [
            parentItem: .loaded(
                [
                    .variation(
                        POSVariation(
                            id: .init(underlyingType: .variation, itemID: 256),
                            name: "Cinamon chestnut latte",
                            formattedPrice: "$5.75",
                            price: "5.75",
                            productID: 134,
                            variationID: 256,
                            parentProductName: parentProduct.name
                        )
                    ),
                    .variation(
                        POSVariation(
                            id: .init(underlyingType: .variation, itemID: 2567),
                            name: "Choco latte",
                            formattedPrice: "$6.5",
                            price: "6.5",
                            productID: 134,
                            variationID: 2567,
                            parentProductName: parentProduct.name
                        )
                    )
                ], hasMoreItems: false)])
    itemsController.itemsViewState = .init(containerState: .content, itemsStack: itemsStack)

    return ChildItemList(parentItem: parentItem,
                         title: parentProduct.name,
                         itemsController: itemsController,
                         itemActionHandler: PointOfSalePreviewItemActionHandler(),
                         analyticsTracker: PointOfSaleItemListAnalyticsTracker(
                            sourceView: .variation,
                            sourceViewType: .list,
                            analytics: EmptyPOSAnalytics()
                         ))
}

#Preview("Variable items load error") {
    let parentProduct = POSVariableParentProduct(
        id: .init(underlyingType: .product, itemID: 1),
        name: "Variable latte",
        productImageSource: nil,
        productID: 1
    )
    let parentItem = POSItem.variableParentProduct(parentProduct)
    let itemsController = PointOfSalePreviewItemsController()
    let itemsStack = ItemsStackState(
        root: .loading([]),
        itemStates: [
            parentItem: .error(.errorOnLoadingVariations())
        ])
    itemsController.itemsViewState = .init(containerState: .content, itemsStack: itemsStack)
    return ChildItemList(parentItem: parentItem,
                         title: parentProduct.name,
                         itemsController: itemsController,
                         itemActionHandler: PointOfSalePreviewItemActionHandler(),
                         analyticsTracker: PointOfSaleItemListAnalyticsTracker(
                            sourceView: .variation,
                            sourceViewType: .list,
                            analytics: EmptyPOSAnalytics()
                         ))
}

#endif
