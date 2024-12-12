import SwiftUI
import Yosemite

struct PointOfSaleRootItemListView: View {
    @EnvironmentObject var posModel: PointOfSaleAggregateModel
    @StateObject var viewHelper: PointOfSaleRootItemListViewHelper

    enum ViewState {
        case rootItemList
        case childItemList(POSParentProduct)
    }
    @State private var state: ViewState = .rootItemList

    var body: some View {
        switch state {
            case .rootItemList:
                VStack {
                    HStack {
                        POSHeaderTitleView(context: .root) {}
                    }
                    PointOfSaleItemListView(itemListState: $posModel.itemListState,
                                            reload: {
                        await posModel.reload()
                    }, loadNextItems: {
                        await posModel.loadNextItems()
                    }) { item in
                        // TODO: try replacing item type with generic "top-level item" (leaf or parent item)
                        switch item {
                            case .product(let product):
                                Button(action: {
                                    posModel.addToCart(product)
                                }, label: {
                                    ProductCardView(product: product)
                                })
                            case .parentProduct(let parentProduct):
                                // TODO: Can try `navigationDestination`
                                Button(action: {
                                    state = .childItemList(parentProduct)
                                    //                            withAnimation {
                                    Task { @MainActor in
                                        await viewHelper.loadChildItems(for: parentProduct)
                                    }
                                    //                            }
                                }, label: {
                                    ParentProductCardView(parentProduct: parentProduct)
                                })
                            case .variation:
                                EmptyView()
                        }
                    }
                }
            case let .childItemList(parentProduct):
                VStack {
                    HStack {
                        POSHeaderTitleView(context: .child(parent: parentProduct, parentItem: .parentProduct(parentProduct))) {
                            state = .rootItemList
                        }
                    }
                    PointOfSaleItemListView(itemListState: $viewHelper.childItemListState,
                                            reload: {
                        await viewHelper.reloadChildItems()
                    }, loadNextItems: {
                        await viewHelper.loadNextChildItems()
                    }) { item in
                        // TODO: try replacing item type with generic child item
                        switch item {
                            case .variation(let variation):
                                Button(action: {
                                    posModel.addToCart(variation)
                                }, label: {
                                    VariationCardView(variation: variation)
                                })
                            default:
                                EmptyView()
                        }
                    }
                }
        }
    }
}

//#Preview {
//    PointOfSaleRootItemListView()
//}
