import SwiftUI
import protocol Storage.GRDBManagerProtocol
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSReceiptServiceProtocol
import protocol Yosemite.POSSearchHistoryProviding
import protocol Yosemite.PluginsServiceProtocol
import class Yosemite.PointOfSaleFixedItemFetchStrategyFactory
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import struct Yosemite.PointOfSaleCouponFetchStrategyFactory
import protocol Yosemite.PointOfSaleCouponServiceProtocol
import protocol Yosemite.PointOfSaleItemFetchStrategyFactoryProtocol
import class Yosemite.PointOfSaleItemService
import protocol Yosemite.PointOfSaleSettingsServiceProtocol
import struct Yosemite.SiteSetting
import protocol Yosemite.PointOfSaleCouponFetchStrategyFactoryProtocol

/// periphery: ignore - public in preparation of move to POS module
public struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @StateObject private var posSheetManager = POSSheetManager()
    @StateObject private var posCoverManager = POSFullScreenCoverManager()
    @State private var orderListModel: POSOrderListModel
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

    /// periphery: ignore - public in preparation of move to POS module
    public init(siteID: Int64,
         itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol,
         popularItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol,
         couponProvider: PointOfSaleCouponServiceProtocol,
         couponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol,
         orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol,
         orderService: POSOrderServiceProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         receiptService: POSReceiptServiceProtocol,
         pluginsService: PluginsServiceProtocol,
         settingsService: PointOfSaleSettingsServiceProtocol,
         collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking,
         searchHistoryService: POSSearchHistoryProviding,
         barcodeScanService: PointOfSaleBarcodeScanServiceProtocol,
         posEligibilityChecker: POSEntryPointEligibilityCheckerProtocol,
         siteTimezone: TimeZone = .current,
         defaultSiteName: String?,
         siteSettings: [SiteSetting],
         grdbManager: GRDBManagerProtocol?,
         catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?,
         services: POSDependencyProviding) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        // Use observable controller with GRDB if available and feature flag is enabled, otherwise fall back to standard controller
        // Note: We check feature flag here for eligibility. Once eligibility checking is
        // refactored to be more centralized, this check can be simplified.
        let isGRDBEnabled = services.featureFlags.isFeatureFlagEnabled(.pointOfSaleLocalCatalogi1)
        if let grdbManager = grdbManager, let catalogSyncCoordinator, isGRDBEnabled {
            self.itemsController = PointOfSaleObservableItemsController(
                siteID: siteID,
                grdbManager: grdbManager,
                currencySettings: services.currency.currencySettings,
                catalogSyncCoordinator: catalogSyncCoordinator
            )
        } else {
            self.itemsController = PointOfSaleItemsController(
                itemProvider: PointOfSaleItemService(currencySettings: services.currency.currencySettings),
                itemFetchStrategyFactory: itemFetchStrategyFactory,
                analyticsProvider: services.analytics
            )
        }
        self.purchasableItemsSearchController = PointOfSaleItemsController(
            itemProvider: PointOfSaleItemService(currencySettings: services.currency.currencySettings),
            itemFetchStrategyFactory: itemFetchStrategyFactory,
            initialState: .init(containerState: .content,
                                itemsStack: .init(root: .loaded([], hasMoreItems: true), itemStates: [:])),
            analyticsProvider: services.analytics
        )
        self.couponsController = PointOfSaleCouponsController(itemProvider: couponProvider,
                                                              fetchStrategyFactory: couponFetchStrategyFactory,
                                                              analyticsProvider: services.analytics)
        self.couponsSearchController = PointOfSaleCouponsController(itemProvider: couponProvider,
                                                                    fetchStrategyFactory: couponFetchStrategyFactory,
                                                                    analyticsProvider: services.analytics)
        self.cardPresentPaymentService = cardPresentPaymentService
        let receiptSender = POSReceiptSender(siteID: siteID,
                                             orderService: orderService,
                                             receiptService: receiptService,
                                             analytics: services.analytics,
                                             pluginsService: pluginsService)
        self.orderController = PointOfSaleOrderController(orderService: orderService,
                                                          receiptSender: receiptSender,
                                                          currencySettingsProvider: services.currency,
                                                          analytics: services.analytics)
        self.settingsController = PointOfSaleSettingsController(siteID: siteID,
                                                                settingsService: settingsService,
                                                                cardPresentPaymentService: cardPresentPaymentService,
                                                                pluginsService: pluginsService,
                                                                defaultSiteName: defaultSiteName,
                                                                siteSettings: siteSettings,
                                                                grdbManager: grdbManager,
                                                                catalogSyncCoordinator: catalogSyncCoordinator)
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = PointOfSaleItemsController(
            itemProvider: PointOfSaleItemService(currencySettings: services.currency.currencySettings),
            itemFetchStrategyFactory: popularItemFetchStrategyFactory,
            analyticsProvider: services.analytics
        )
        self.barcodeScanService = barcodeScanService
        self.posEntryPointController = POSEntryPointController(eligibilityChecker: posEligibilityChecker)
        let ordersController = POSOrderListController(orderListFetchStrategyFactory: orderListFetchStrategyFactory)
        self.orderListModel = POSOrderListModel(ordersController: ordersController, receiptSender: receiptSender)
        self.siteTimezone = siteTimezone
        self.services = services
    }

    public var body: some View {
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
    PointOfSaleEntryPointView(
        siteID: 1,
        itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
        popularItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
        couponProvider: PointOfSaleCouponServicePreview(),
        couponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryPreview(),
        orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryPreview(),
        orderService: POSOrderServicePreview(),
        onPointOfSaleModeActiveStateChange: { _ in },
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        receiptService: POSReceiptServicePreview(),
        pluginsService: PluginsServicePreview(),
        settingsService: PointOfSaleSettingsServicePreview(),
        collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentPreviewAnalytics(),
        searchHistoryService: PointOfSalePreviewHistoryService(),
        barcodeScanService: PointOfSalePreviewBarcodeScanService(),
        posEligibilityChecker: PointOfSalePreviewTabEligibilityChecker(),
        defaultSiteName: "Demo Store",
        siteSettings: [],
        grdbManager: nil,
        catalogSyncCoordinator: nil,
        services: POSPreviewServices()
    )
}

#endif
