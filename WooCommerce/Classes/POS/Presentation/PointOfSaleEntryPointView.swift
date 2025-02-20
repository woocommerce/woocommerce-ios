import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel
    @StateObject private var posModalManager = POSModalManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemsController: PointOfSaleItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let posModel = PointOfSaleAggregateModel(
            itemsController: itemsController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker)

        self._posModel = State(wrappedValue: posModel)
    }

    var body: some View {
        PointOfSaleDashboardView()
        .environmentObject(posModalManager)
        .environment(posModel)
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
            posModalManager.onDisappear()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    PointOfSaleEntryPointView(itemsController: PointOfSalePreviewItemsController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController(),
                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics())
}
#endif
