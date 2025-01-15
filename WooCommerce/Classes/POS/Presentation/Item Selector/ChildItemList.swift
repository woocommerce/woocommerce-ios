import SwiftUI
import Yosemite

/// Displays a scrollable list of child items in POS.
struct ChildItemList: View {
    private let parentItem: POSItem
    private let title: String
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @Environment(\.dismiss) private var dismiss

    // Used for refresh control workaround for an issue where the view is redrawn and the refresh control task is canceled.
    // As a workaround, Task is perserved and can be associated with a unique ID from each refresh control trigger.
    @State private var refreshControlTaskID: UUID?

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
            case .loading, .loaded, .inlineError:
                listView
            case let .error(error):
                errorView(error: error)
            }
        }
        .background(Color.posPrimaryBackground)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            // Only allows one refresh task at a time now that the refresh control is released on redraw.
            guard refreshControlTaskID == nil else {
                return
            }
            refreshControlTaskID = .init()
        }
        .task(id: refreshControlTaskID) {
            guard refreshControlTaskID != nil else {
                return
            }
            await posModel.loadItems(base: .parent(parentItem))
            refreshControlTaskID = nil
        }
        .task {
            guard state.items.isEmpty else {
                return
            }
            await posModel.loadItems(base: .parent(parentItem))
        }
    }
}

private extension ChildItemList {
    @ViewBuilder var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                    .foregroundColor(.primary)
            }
            POSHeaderTitleView(title: title)
            Spacer()
        }
        .padding(.horizontal, Constants.itemListPadding)
    }

    @ViewBuilder
    var listView: some View {
        VStack {
            headerView

            ItemList(state: state,
                     node: .parent(parentItem))
                .transition(.opacity)
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

private extension ChildItemList {
    enum Localization {
        static let back = NSLocalizedString(
            "pos.childItemList.back",
            value: "Back",
            comment: "Back button title in the child item list screen."
        )
    }

    enum Constants {
        static let itemListPadding: CGFloat = 16
    }
}

#if DEBUG

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
                                                                variationID: 256
                                                            )
                                                        ),
                                                        .variation(
                                                            POSVariation(
                                                                id: .init(),
                                                                name: "Choco latte",
                                                                formattedPrice: "$6.5",
                                                                price: "6.5",
                                                                productID: 134,
                                                                variationID: 256
                                                            )
                                                        )
                                                    ], hasMoreItems: false)]))
    let posModel = PointOfSaleAggregateModel(
        itemsController: itemsController,
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    return ChildItemList(parentItem: parentItem, title: parentProduct.name)
        .environmentObject(posModel)
}

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
        orderController: PointOfSalePreviewOrderController())
    return ChildItemList(parentItem: parentItem, title: parentProduct.name)
        .environmentObject(posModel)
}

#endif
