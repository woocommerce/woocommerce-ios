import SwiftUI

struct POSSaleTabView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posNavigationModel) private var navigationModel
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()

    @State private var isCartExpanded: Bool = false

    var body: some View {
        @Bindable var viewStateCoordinator = posModel.viewStateCoordinatorForView
        @Bindable var navModel = navigationModel
        ItemListView(selectedItemListType: $viewStateCoordinator.selectedItemListType,
                     searchTerm: $viewStateCoordinator.searchTerm)
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
            .posFullScreenCover(isPresented: $navModel.isShowingCheckout) {
                POSCheckoutView(isPresented: $navModel.isShowingCheckout)
            }
            .onChange(of: posModel.orderStage) { _, newStage in
                switch newStage {
                case .finalizing:
                    navigationModel.showCheckout()
                case .building:
                    navigationModel.dismissCheckout()
                }
            }
            .onChange(of: navigationModel.isShowingCheckout) { _, isShowing in
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
