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
            // TODO: handle empty, error states
            //            switch viewModel.itemListState {
            //                case .initialLoading:
            //                    PointOfSaleLoadingView()
            //                        .transition(.opacity)
            //                        .ignoresSafeArea()
            //                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                        .edgesIgnoringSafeArea(.all)
            //                case .empty:
            //                    PointOfSaleItemListEmptyView()
            //                case .error(let errorContents):
            //                    PointOfSaleItemListErrorView(error: errorContents, onRetry: {
            //                        Task {
            //                            await viewModel.loadInitialItems()
            //                        }
            //                    })
            //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                    .edgesIgnoringSafeArea(.all)
            //                case .loading, .loaded:
            //
            //            }
            switch state {
                case .rootItemList:
                    VStack {
                        HStack {
                            POSHeaderTitleView() {}
                        }
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
                                // TODO: Can try `navigationDestination`
                                Button(action: {
                                    viewModel.showVariationItems(for: item)
                                    state = .variationItemList(item)
                                }, label: {
                                    ParentProductCardView(parentProduct: item)
                                })
                                // NOTE: This navigates to the destination view in fullscreen
//                                NavigationLink {
//                                    Text("Child items for \(item.name)")
//                                } label: {
//                                    ParentProductCardView(parentProduct: item)
//                                }
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
                            }
//                            Button(action: {
//                                posModel.addToCart(variation)
//                            }, label: {
//                                VariationCardView(variation: variation)
//                            })
                        }
                        //                    PointOfSaleItemListView(itemListState: $viewModel.childItemListState,
                        //                                            reload: {
                        //                        await viewModel.reloadChildItems()
                        //                    }, loadNextItems: {
                        //                        await viewModel.loadNextChildItems()
                        //                    }) { item in
                        //                        // TODO: try replacing item type with generic child item
                        //                        switch item {
                        //                            case .variation(let variation):
                        //                                Button(action: {
                        //                                    posModel.addToCart(variation)
                        //                                }, label: {
                        //                                    VariationCardView(variation: variation)
                        //                                })
                        //                            default:
                        //                                EmptyView()
                        //                        }
                        //                    }
                    }
            }
        }
        .task {
            await viewModel.loadInitialItems()
        }
        .fullScreenCover(isPresented: $viewModel.isShowingLoadingView) {
            // TODO: recover opacity transition
            PointOfSaleLoadingView()
                .transition(.opacity)
                .ignoresSafeArea()
        }
    }
}

//struct FullScreenCoverView: View {
//    @Binding var isPresented: Bool
//    @State private var opacity: Double = 0.0
//
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all) // Background color
//                .opacity(opacity) // Apply opacity to background
//
//            PointOfSaleLoadingView()
//        }
//        .onAppear {
//            withAnimation {
//                opacity = 1.0 // Fade in when appearing
//            }
//        }
//        .onDisappear {
//            opacity = 0.0 // Reset opacity when disappearing
//        }
//    }
//}

//#Preview {
//    PointOfSaleRootItemListView()
//}
