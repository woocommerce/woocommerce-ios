import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol
import protocol WooFoundation.Analytics

struct PointOfSaleEntryPointView: View {
    @StateObject private var posModel: PointOfSaleAggregateModel
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

        self._posModel = StateObject(wrappedValue: posModel)
    }

    var body: some View {
        PointOfSaleDashboardView()
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
