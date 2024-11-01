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
    @StateObject private var posModel: PointOfSaleAggregateModel

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
         analytics: Analytics) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let posModel = PointOfSaleAggregateModel(
            itemProvider: itemProvider,
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: orderService,
            analytics: analytics)

        let totalsViewModel = TotalsViewModel(
            posModel: posModel,
            currencyFormatter: currencyFormatter)
        let cartViewModel = CartViewModel(
            analytics: analytics,
            posModel: posModel)
        let itemListViewModel = ItemListViewModel(posModel: posModel)

        self._viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            posModel: posModel,
            connectivityObserver: ServiceLocator.connectivityObserver)
        )
        self._cartViewModel = StateObject(wrappedValue: cartViewModel)
        self._totalsViewModel = StateObject(wrappedValue: totalsViewModel)
        self._itemListViewModel = StateObject(wrappedValue: itemListViewModel)
        self._posModel = StateObject(wrappedValue: posModel)
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel,
                                 totalsViewModel: totalsViewModel,
                                 cartViewModel: cartViewModel,
                                 itemListViewModel: itemListViewModel,
                                 posModel: posModel)
        .environmentObject(posModalManager)
        .environmentObject(posModel)
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
