import SwiftUI
import protocol Yosemite.POSSearchHistoryProviding
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol

struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @StateObject private var posSheetManager = POSSheetManager()
    @StateObject private var posCoverManager = POSFullScreenCoverManager()
    @State private var orderListModel: PointOfSaleOrderListModel
    @State private var posEntryPointController: POSEntryPointController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let settingsController: PointOfSaleSettingsControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol
    private let siteTimezone: TimeZone
    private let services: POSDependencyProviding

    init(itemsController: PointOfSaleItemsControllerProtocol,
         purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         couponsController: PointOfSaleCouponsControllerProtocol,
         couponsSearchController: PointOfSaleSearchingItemsControllerProtocol,
         ordersController: PointOfSaleSearchingOrderListControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol,
         receiptSender: POSReceiptSending,
         settingsController: PointOfSaleSettingsControllerProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         popularPurchasableItemsController: PointOfSaleItemsControllerProtocol,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         siteTimezone: TimeZone = .current,
         services: POSDependencyProviding) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        self.itemsController = itemsController
        self.purchasableItemsSearchController = purchasableItemsSearchController
        self.couponsController = couponsController
        self.couponsSearchController = couponsSearchController
        self.cardPresentPaymentService = cardPresentPaymentService
        self.orderController = orderController
        self.settingsController = settingsController
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = popularPurchasableItemsController
        self.barcodeScanService = barcodeScanService
        self.posEntryPointController = POSEntryPointController(eligibilityChecker: posEligibilityChecker,
                                                               featureFlagService: services.featureFlags)
        self.orderListModel = PointOfSaleOrderListModel(ordersController: ordersController, receiptSender: receiptSender)
        self.siteTimezone = siteTimezone
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
                settingsController: settingsController,
                analytics: services.analytics,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
                searchHistoryService: searchHistoryService,
                popularPurchasableItemsController: popularPurchasableItemsController,
                barcodeScanService: barcodeScanService)
        }
        .environment(\.posAnalytics, services.analytics)
        .environment(\.posCurrencyProvider, services.currency)
        .environment(\.posFeatureFlags, services.featureFlags)
        .environment(\.posConnectivityProvider, services.connectivity)
        .environment(\.posExternalNavigation, services.externalNavigation)
        .environment(\.posExternalViews, services.externalViews)
        .environmentObject(posModalManager)
        .environmentObject(posSheetManager)
        .environmentObject(posCoverManager)
        .environment(orderListModel)
        .environment(\.siteTimezone, siteTimezone)
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
#Preview {
    PointOfSaleEntryPointView(itemsController: PointOfSalePreviewItemsController(),
                              purchasableItemsSearchController: PointOfSalePreviewItemsController(),
                              couponsController: PointOfSalePreviewCouponsController(),
                              couponsSearchController: PointOfSalePreviewCouponsController(),
                              ordersController: PointOfSalePreviewOrderListController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController(),
                              receiptSender: POSReceiptSenderPreview(),
                              settingsController: PointOfSaleSettingsPreviewController(),
                              collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentPreviewAnalytics(),
                              searchHistoryService: PointOfSalePreviewHistoryService(),
                              popularPurchasableItemsController: PointOfSalePreviewItemsController(),
                              barcodeScanService: PointOfSalePreviewBarcodeScanService(),
                              posEligibilityChecker: POSTabEligibilityChecker(siteID: 0),
                              services: POSPreviewServices())
}

#endif
