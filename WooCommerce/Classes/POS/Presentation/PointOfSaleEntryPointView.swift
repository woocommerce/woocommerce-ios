import SwiftUI
import protocol Yosemite.POSSearchHistoryProviding
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol

@available(iOS 17.0, *)
struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @State private var posEntryPointController: POSEntryPointController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol
    private let services: POSDependencyProviding

    init(itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         services: POSDependencyProviding) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.posEntryPointController = POSEntryPointController(eligibilityChecker: posEligibilityChecker)
        self.services = services
    }

    var body: some View {
        Group {
            if let posModel {
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
                entryPointController: posEntryPointController,
                itemsController: itemsController,
                purchasableItemsSearchController: purchasableItemsSearchController,
                couponsController: couponsController,
                couponsSearchController: couponsSearchController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: services.analytics,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                searchHistoryService: searchHistoryService,
                popularPurchasableItemsController: popularPurchasableItemsController,
                barcodeScanService: barcodeScanService)
        }
        .environmentObject(posModalManager)
        .environment(\.posAnalytics, services.analytics)
        .environment(\.posCurrency, services.currency)
        .injectKeyboardObserver()
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
                              couponsSearchController: PointOfSalePreviewCouponsController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController(),
                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentPreviewAnalytics(),
                              searchHistoryService: PointOfSalePreviewHistoryService(),
                              popularPurchasableItemsController: PointOfSalePreviewItemsController(),
                              barcodeScanService: PointOfSalePreviewBarcodeScanService(),
                              posEligibilityChecker: POSTabEligibilityChecker(siteID: 0),
                              services: POSPreviewServices())
}

#endif
