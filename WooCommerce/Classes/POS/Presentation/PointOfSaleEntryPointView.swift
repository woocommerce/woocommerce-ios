import SwiftUI
import protocol Yosemite.POSSearchHistoryProviding

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularItemsController: PointOfSalePopularItemsControllerProtocol

    init(itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularItemsController: PointOfSalePopularItemsControllerProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularItemsController = popularItemsController
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
            // We create the posModel in a task, not init, to avoid creating multiple copies during the view's lifecycle.
            // Confusingly, init can be called more than once, but `task` matches the lifecycle.
            // See https://developer.apple.com/documentation/swiftui/state#Store-observable-objects for details.
            posModel = PointOfSaleAggregateModel(
                itemsController: itemsController,
                purchasableItemsSearchController: purchasableItemsSearchController,
                couponsController: couponsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                searchHistoryService: searchHistoryService,
                popularItemsController: popularItemsController)
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
                              purchasableItemsSearchController: PointOfSalePreviewItemsController(),
                              couponsController: PointOfSalePreviewCouponsController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController(),
                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalytics(),
                              searchHistoryService: PointOfSalePreviewHistoryService(),
                              popularItemsController: PointOfSalePreviewPopularItemsController())
}

#endif
