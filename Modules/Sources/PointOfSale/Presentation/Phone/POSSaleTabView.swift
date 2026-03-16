import SwiftUI

struct POSSaleTabView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var sheetManager = POSSheetManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()

    @State private var selectedItemListType: ItemListType = .products(search: false)
    @State private var searchTerm: String = ""
    @State private var cartSheetDetent: PresentationDetent = .cartPeek
    @State private var isShowingCheckout: Bool = false

    var body: some View {
        ItemListView(selectedItemListType: $selectedItemListType,
                     searchTerm: $searchTerm)
            .environmentObject(modalManager)
            .environmentObject(sheetManager)
            .environmentObject(coverManager)
            .sheet(isPresented: .constant(true)) {
                POSCartSheetView(selectedDetent: $cartSheetDetent)
                    .presentationDetents([.cartPeek, .large], selection: $cartSheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .cartPeek))
                    .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $isShowingCheckout) {
                POSCheckoutView(isPresented: $isShowingCheckout)
            }
            .onChange(of: posModel.orderStage) { _, newStage in
                // Sync checkout presentation with order stage
                if newStage == .finalizing {
                    isShowingCheckout = true
                }
            }
            .onChange(of: isShowingCheckout) { _, isShowing in
                // When checkout is dismissed via back button, return to building
                if !isShowing && posModel.orderStage == .finalizing {
                    posModel.addMoreToCart()
                }
            }
    }
}
