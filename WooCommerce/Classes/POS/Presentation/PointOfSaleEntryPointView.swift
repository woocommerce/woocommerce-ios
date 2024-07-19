import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel<TotalsViewModel>

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         hideAppTabBar: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter) {
        self.hideAppTabBar = hideAppTabBar

        let totalsViewModel = TotalsViewModel(orderService: orderService,
                                              cardPresentPaymentService: cardPresentPaymentService,
                                              currencyFormatter: currencyFormatter)

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            itemProvider: itemProvider,
            cardPresentPaymentService: cardPresentPaymentService,
            totalsViewModel: .init(orderService: orderService,
                                   cardPresentPaymentService: cardPresentPaymentService,
                                   currencyFormatter: currencyFormatter))
        )
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel)
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
                              currencyFormatter: .init(currencySettings: .init()))
}
#endif
