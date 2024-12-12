import SwiftUI
import Yosemite

struct PointOfSaleRootItemListView: View {
    @EnvironmentObject var posModel: PointOfSaleAggregateModel
    @ObservedObject var viewModel: PointOfSaleRootItemListViewModel

    enum ViewState {
        case rootItemList
        case variationItemList(POSVariableProductParent)
    }
    @State private var state: ViewState = .rootItemList
    @State private var isShowingLoadingView: Bool = false

    var body: some View {
        Group {
            switch state {
                case .rootItemList:
                    VStack {
                        POSHeaderTitleView()
                        PointOfSaleItemListView(itemListState: $viewModel.itemListState,
                                                reload: {
                            await viewModel.reload()
                        }, loadNextItems: {
                            await viewModel.loadNextItems()
                        }) { item in
                            if let item = item as? POSOrderableItem {
                                Button(action: {
                                    posModel.addToCart(item)
                                }, label: {
                                    ItemCardView(item: item)
                                })
                            } else if let item = item as? POSVariableProductParent {
                                Button(action: {
                                    viewModel.showVariationItems(for: item)
                                    state = .variationItemList(item)
                                }, label: {
                                    ParentProductCardView(parentProduct: item)
                                })
                            } else {
                                ItemCardView(item: item)
                            }
                        }
                    }
                case let .variationItemList(parentProduct):
                    VStack {
                        HStack {
                            Button {
                                state = .rootItemList
                            } label: {
                                Image(systemName: "chevron.backward")
                                    .font(.posTitleRegular)
                            }
                            Spacer()
                            Text(parentProduct.name)
                            Spacer()
                        }
                        PointOfSaleItemListView(itemListState: $viewModel.variationItemListState,
                                                reload: {
                            await viewModel.reloadVariations()
                        }, loadNextItems: {
                            await viewModel.loadVariationNextItems()
                        }) { item in
                            if let item = item as? POSOrderableItem {
                                Button(action: {
                                    posModel.addToCart(item)
                                }, label: {
                                    ItemCardView(item: item)
                                })
                            } else {
                                EmptyView()
                            }
                        }
                    }
            }
        }
//        .task {
//            await viewModel.loadInitialItems()
//        }
//        .fullScreenCover(item: $viewModel.fullscreenState) { fullscreenState in
//            switch fullscreenState {
//                case .initialLoading:
//                    PointOfSaleLoadingView()
//                        .transition(.opacity)
//                        .ignoresSafeArea()
//                case .empty:
//                    PointOfSaleItemListEmptyView()
//                case .error(let error):
//                    PointOfSaleItemListErrorView(error: error, onRetry: {
//                        Task {
//                            await viewModel.loadInitialItems()
//                        }
//                    })
//            }
//        }
    }
}

//#Preview {
//    PointOfSaleRootItemListView()
//}
