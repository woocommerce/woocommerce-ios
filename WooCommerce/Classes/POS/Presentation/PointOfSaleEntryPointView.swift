import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol
import protocol WooFoundation.Analytics

struct PointOfSaleEntryPointView: View {
    @StateObject private var posModel: PointOfSaleAggregateModel
    @StateObject private var viewModel: PointOfSaleDashboardViewModel
    @StateObject private var totalsViewModel: TotalsViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var posModalManager = POSModalManager()

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
         analytics: Analytics) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let posModel = PointOfSaleAggregateModel(itemProvider: itemProvider,
                                                 cardPresentPaymentService: cardPresentPaymentService,
                                                 orderService: orderService)
        let totalsViewModel = TotalsViewModel(posModel: posModel,
                                              cardPresentPaymentService: cardPresentPaymentService)
        let cartViewModel = CartViewModel(posModel: posModel)

        self._posModel = StateObject(wrappedValue: posModel)
        self._viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            posModel: posModel,
            totalsViewModel: totalsViewModel,
            cartViewModel: cartViewModel,
            connectivityObserver: ServiceLocator.connectivityObserver)
        )
        self._cartViewModel = StateObject(wrappedValue: cartViewModel)
        self._totalsViewModel = StateObject(wrappedValue: totalsViewModel)
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel,
                                 totalsViewModel: totalsViewModel,
                                 cartViewModel: cartViewModel)
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
