import SwiftUI

struct POSSaleTabView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()

    @State private var isCartExpanded: Bool = false
    @State private var isShowingCheckout: Bool = false

    var body: some View {
        @Bindable var viewStateCoordinator = posModel.viewStateCoordinatorForView
        ItemListView(selectedItemListType: $viewStateCoordinator.selectedItemListType,
                     searchTerm: $viewStateCoordinator.searchTerm)
            .environment(\.dynamicTypeSize, .small)
            .environmentObject(modalManager)
            .environmentObject(sheetManager)
            .environmentObject(coverManager)
            .safeAreaInset(edge: .bottom) {
                if posModel.cart.isNotEmpty {
                    POSCartPeekView(
                        onExpandCart: {
                            isCartExpanded = true
                        },
                        onCheckout: {
                            Task { @MainActor in
                                trackCheckoutTapped()
                                await posModel.prepareCheckout()
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: posModel.cart.isNotEmpty)
            .task {
                await posModel.purchasableItemsController.loadItems(base: .root)
            }
            .sheet(isPresented: $isCartExpanded) {
                POSCartSheetView()
                    .presentationDragIndicator(.visible)
            }
            .posFullScreenCover(isPresented: $isShowingCheckout) {
                POSCheckoutView(isPresented: $isShowingCheckout)
            }
            .onChange(of: posModel.orderStage) { _, newStage in
                switch newStage {
                case .finalizing:
                    isShowingCheckout = true
                case .building:
                    isShowingCheckout = false
                }
            }
            .onChange(of: isShowingCheckout) { _, isShowing in
                if !isShowing && posModel.orderStage == .finalizing {
                    posModel.addMoreToCart()
                }
            }
    }

    private func trackCheckoutTapped() {
        analytics.track(
            event: .PointOfSale.checkoutTapped(
                purchasableItemsInCart: posModel.cart.purchasableItems.count,
                couponsInCart: posModel.cart.coupons.count
            )
        )
    }
}
