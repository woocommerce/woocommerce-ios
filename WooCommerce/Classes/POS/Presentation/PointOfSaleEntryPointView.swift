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
    @StateObject private var posModalManager = POSModalManager()

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
         analytics: Analytics) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

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
            itemListViewModel: itemListViewModel,
            connectivityObserver: ServiceLocator.connectivityObserver)
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
        .environmentObject(posModalManager)
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
        }
    }
}

#if DEBUG
import class WooFoundation.MockAnalyticsPreview
import class WooFoundation.MockAnalyticsProviderPreview

#Preview {
    PointOfSaleEntryPointView(itemProvider: POSItemProviderPreview(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderService: POSOrderPreviewService(),
                              currencyFormatter: .init(currencySettings: .init()),
                              analytics: MockAnalyticsPreview(userHasOptedIn: true,
                                                              analyticsProvider: MockAnalyticsProviderPreview()))
}
#endif
