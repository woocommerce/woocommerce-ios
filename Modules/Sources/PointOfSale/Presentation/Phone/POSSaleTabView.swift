import SwiftUI

struct POSSaleTabView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()

    @State private var selectedItemListType: ItemListType = .products(search: false)
    @State private var searchTerm: String = ""
    @State private var isCartExpanded: Bool = false
    @State private var isShowingCheckout: Bool = false

    var body: some View {
        ItemListView(selectedItemListType: $selectedItemListType,
                     searchTerm: $searchTerm)
            .environmentObject(modalManager)
            .environmentObject(sheetManager)
            .environmentObject(coverManager)
            .safeAreaInset(edge: .bottom) {
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
            }
            .sheet(isPresented: $isCartExpanded) {
                POSCartSheetView()
                    .presentationDragIndicator(.visible)
            }
            .posFullScreenCover(isPresented: $isShowingCheckout) {
                POSCheckoutView(isPresented: $isShowingCheckout)
            }
            .onChange(of: posModel.orderStage) { _, newStage in
                if newStage == .finalizing {
                    isShowingCheckout = true
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
