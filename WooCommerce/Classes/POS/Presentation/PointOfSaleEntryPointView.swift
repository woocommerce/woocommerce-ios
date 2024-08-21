import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol
import protocol WooFoundation.Analytics

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel
    @StateObject private var totalsViewModel: TotalsViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var itemListViewModel: ItemListViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         hideAppTabBar: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
         analytics: Analytics) {
        self.hideAppTabBar = hideAppTabBar

        let totalsViewModel = TotalsViewModel(orderService: orderService,
                                              cardPresentPaymentService: cardPresentPaymentService,
                                              currencyFormatter: currencyFormatter,
                                              paymentState: .acceptingCard)
        let cartViewModel = CartViewModel(analytics: analytics)
        let itemListViewModel = ItemListViewModel(itemProvider: itemProvider)

        self._viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            cardPresentPaymentService: cardPresentPaymentService,
            totalsViewModel: totalsViewModel,
            cartViewModel: cartViewModel,
            itemListViewModel: itemListViewModel)
        )
        self._cartViewModel = StateObject(wrappedValue: cartViewModel)
        self._totalsViewModel = StateObject(wrappedValue: totalsViewModel)
        self._itemListViewModel = StateObject(wrappedValue: itemListViewModel)
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel,
                                 totalsViewModel: totalsViewModel,
                                 cartViewModel: cartViewModel,
                                 itemListViewModel: itemListViewModel)
            .onAppear {
                hideAppTabBar(true)
            }
            .onDisappear {
                hideAppTabBar(false)
            }
    }
}

#if DEBUG
#Preview {
    PointOfSaleEntryPointView(itemProvider: POSItemProviderPreview(),
                              hideAppTabBar: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderService: POSOrderPreviewService(),
                              currencyFormatter: .init(currencySettings: .init()), analytics: ServiceLocator.analytics)
}
#endif
