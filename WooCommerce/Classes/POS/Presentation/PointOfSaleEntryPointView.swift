import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking

    init(itemsController: PointOfSaleItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
    }

    var body: some View {
        Group {
            if let posModel = posModel {
                PointOfSaleDashboardView()
                    .environment(posModel)
            } else {
                PointOfSaleLoadingView()
            }
        }
        .task {
            posModel = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker)
        }
        .environmentObject(posModalManager)
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
            posModalManager.onDisappear()
            posModel?.pointOfSaleClosed()
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
