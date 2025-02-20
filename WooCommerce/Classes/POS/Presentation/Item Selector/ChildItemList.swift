import SwiftUI
import Yosemite

/// Displays a scrollable list of child items in POS.
@available(iOS 17.0, *)
struct ChildItemList: View {
    private let parentItem: POSItem
    private let title: String
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dismiss) private var dismiss

    private var state: ItemListState {
        posModel.itemsViewState.itemsStack
            .itemStates[parentItem] ??
            .loading([])
    }

    init(parentItem: POSItem, title: String) {
        self.parentItem = parentItem
        self.title = title
    }

    var body: some View {
        VStack {
            switch state {
            case .loaded([], _):
                emptyView
            case .loading, .loaded, .inlineError:
                listView
            case let .error(error):
                errorView(error: error)
            }
        }
        .background(Color.posSurface)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard state.items.isEmpty else {
                return
            }
            await posModel.loadItems(base: .parent(parentItem))
        }
    }
}

@available(iOS 17.0, *)
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
        VStack {
            headerView

            ItemList(state: state,
                     node: .parent(parentItem))
                .transition(.opacity)
                .refreshable {
                    ServiceLocator.analytics.track(.pointOfSaleVariationsPullToRefresh)
                    await posModel.refreshItems(base: .parent(parentItem))
                }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        VStack {
            headerView
            PointOfSaleItemListEmptyView(base: .parent(parentItem))
        }
    }

    @ViewBuilder
    func errorView(error: PointOfSaleErrorState) -> some View {
        ZStack {
            VStack {
                headerView
                Spacer()
            }

            PointOfSaleItemListErrorView(error: error, onRetry: {
                Task {
                    await posModel.loadItems(base: .parent(parentItem))
                }
            })
            .zIndex(1)
        }
    }
}

@available(iOS 17.0, *)
private extension ChildItemList {
    enum Localization {
        static let back = NSLocalizedString(
            "pos.childItemList.back",
            value: "Back",
            comment: "Back button title in the child item list screen."
        )
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Variable product child items") {
    let parentProduct = POSVariableParentProduct(
        id: .init(),
        name: "Variable latte",
        productImageSource: nil,
        productID: 1
    )
    let parentItem = POSItem.variableParentProduct(parentProduct)
    let itemsController = PointOfSalePreviewItemsController()
    itemsController.itemsViewState = .init(containerState: .content,
                                           itemsStack: ItemsStackState(
                                            root: .loading([]),
                                            itemStates: [
                                                parentItem: .loaded(
                                                    [
                                                        .variation(
                                                            POSVariation(
                                                                id: .init(),
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
                                                                id: .init(),
                                                                name: "Choco latte",
                                                                formattedPrice: "$6.5",
                                                                price: "6.5",
                                                                productID: 134,
                                                                variationID: 256,
                                                                parentProductName: parentProduct.name
                                                            )
                                                        )
                                                    ], hasMoreItems: false)]))
    let posModel = PointOfSaleAggregateModel(
        itemsController: itemsController,
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    return ChildItemList(parentItem: parentItem, title: parentProduct.name)
        .environment(posModel)
}

@available(iOS 17.0, *)
#Preview("Variable items load error") {
    let parentProduct = POSVariableParentProduct(
        id: .init(),
        name: "Variable latte",
        productImageSource: nil,
        productID: 1
    )
    let parentItem = POSItem.variableParentProduct(parentProduct)
    let itemsController = PointOfSalePreviewItemsController()
    itemsController.itemsViewState = .init(containerState: .content,
                                           itemsStack: ItemsStackState(
                                            root: .loading([]),
                                            itemStates: [
                                                parentItem: .error(.errorOnLoadingVariations())
                                            ]))
    let posModel = PointOfSaleAggregateModel(
        itemsController: itemsController,
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
    return ChildItemList(parentItem: parentItem, title: parentProduct.name)
        .environment(posModel)
}

#endif
