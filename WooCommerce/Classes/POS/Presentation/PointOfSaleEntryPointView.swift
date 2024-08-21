import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel
    @StateObject private var totalsViewModel: TotalsViewModel
    @StateObject private var cartViewModel: CartViewModel
    @StateObject private var itemListViewModel: ItemListViewModel

    private let isPointOfSaleModeEnabled: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         isPointOfSaleModeEnabled: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter) {
        self.isPointOfSaleModeEnabled = isPointOfSaleModeEnabled

        let totalsViewModel = TotalsViewModel(orderService: orderService,
                                              cardPresentPaymentService: cardPresentPaymentService,
                                              currencyFormatter: currencyFormatter,
                                              paymentState: .acceptingCard)
        let cartViewModel = CartViewModel()
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
                isPointOfSaleModeEnabled(true)
            }
            .onDisappear {
                isPointOfSaleModeEnabled(false)
            }
    }
}

#if DEBUG
#Preview {
    PointOfSaleEntryPointView(itemProvider: POSItemProviderPreview(),
                              isPointOfSaleModeEnabled: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderService: POSOrderPreviewService(),
                              currencyFormatter: .init(currencySettings: .init()))
}
#endif
