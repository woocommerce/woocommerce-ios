import SwiftUI
import class WooFoundation.CurrencyFormatter
import protocol Storage.GRDBManagerProtocol
import protocol Yosemite.POSCatalogSyncCoordinatorProtocol
import protocol Yosemite.POSOrderListFetchStrategyFactoryProtocol
import protocol Yosemite.POSBookingListFetchStrategyFactoryProtocol
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSRefundsServiceProtocol
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
import protocol Yosemite.PointOfSaleItemServiceProtocol

/// periphery: ignore - public in preparation of move to POS module
public struct PointOfSaleEntryPointView: View {
    @State private var posModel: PointOfSaleAggregateModel?
    @StateObject private var posModalManager = POSModalManager()
    @StateObject private var posSheetManager = POSSheetManager()
    @StateObject private var posCoverManager = POSFullScreenCoverManager()
    @State private var orderListModel: POSOrderListModel
    @State private var bookingsModel: POSBookingsModel?
    @State private var posEntryPointController: POSEntryPointController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let itemsController: PointOfSaleItemsControllerProtocol
    private let purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let couponsController: PointOfSaleCouponsControllerProtocol
    private let couponsSearchController: PointOfSaleSearchingItemsControllerProtocol
    private let cardPresentPaymentService: CardPresentPaymentFacade
    private let orderController: PointOfSaleOrderControllerProtocol
    private let settingsController: POSSettingsControllerProtocol
    private let collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking
    private let searchHistoryService: POSSearchHistoryProviding
    private let popularPurchasableItemsController: PointOfSaleItemsControllerProtocol
    private let barcodeScanService: PointOfSaleBarcodeScanServiceProtocol
    private let receiptSender: POSReceiptSending
    private let siteTimezone: TimeZone
    private let services: POSDependencyProviding
    private let siteID: Int64
    private let catalogSyncCoordinator: POSCatalogSyncCoordinatorProtocol?
    private let isLocalCatalogEligible: Bool
    private let isBookingsEligible: Bool

    /// periphery: ignore - public in preparation of move to POS module
    public init(siteID: Int64,
         itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol,
         popularItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryProtocol,
         couponProvider: PointOfSaleCouponServiceProtocol,
         couponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol,
         orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol,
         bookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol?,
         isBookingsEligible: Bool,
         orderService: POSOrderServiceProtocol,
         refundsService: POSRefundsServiceProtocol,
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
         isLocalCatalogEligible: Bool,
         services: POSDependencyProviding,
         itemProvider: PointOfSaleItemServiceProtocol? = nil) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let selectedItemProvider = itemProvider ?? PointOfSaleItemService(currencySettings: services.currency.currencySettings)

        // Use observable controller with GRDB if local catalog is eligible,
        // otherwise fall back to standard controller.
        if isLocalCatalogEligible, let grdbManager = grdbManager, let catalogSyncCoordinator {
            self.itemsController = PointOfSaleObservableItemsController(
                siteID: siteID,
                grdbManager: grdbManager,
                currencySettings: services.currency.currencySettings,
                catalogSyncCoordinator: catalogSyncCoordinator
            )
        } else {
            self.itemsController = PointOfSaleItemsController(
                itemProvider: selectedItemProvider,
                itemFetchStrategyFactory: itemFetchStrategyFactory,
                analyticsProvider: services.analytics
            )
        }
        self.purchasableItemsSearchController = PointOfSaleItemsController(
            itemProvider: selectedItemProvider,
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
                                                                catalogSyncCoordinator: catalogSyncCoordinator,
                                                                isLocalCatalogEligible: isLocalCatalogEligible)
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker
        self.searchHistoryService = searchHistoryService
        self.popularPurchasableItemsController = PointOfSaleItemsController(
            itemProvider: selectedItemProvider,
            itemFetchStrategyFactory: popularItemFetchStrategyFactory,
            analyticsProvider: services.analytics
        )
        self.barcodeScanService = barcodeScanService
        self.receiptSender = receiptSender
        self.posEntryPointController = POSEntryPointController(eligibilityChecker: posEligibilityChecker)
        let ordersController = POSOrderListController(orderListFetchStrategyFactory: orderListFetchStrategyFactory,
                                                      refundsService: refundsService,
                                                      featureFlags: services.featureFlags,
                                                      currencySettingsProvider: services.currency,
                                                      currencyFormatter: CurrencyFormatter(currencySettings: services.currency.currencySettings))
        self.orderListModel = POSOrderListModel(ordersController: ordersController, receiptSender: receiptSender)
        if let bookingListFetchStrategyFactory {
            let bookingsController = POSBookingListController(bookingListFetchStrategyFactory: bookingListFetchStrategyFactory,
                                                               siteTimezone: siteTimezone)
            self.bookingsModel = POSBookingsModel(
                bookingsController: bookingsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderService: orderService,
                receiptSender: receiptSender,
                collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker)
        } else {
            self.bookingsModel = nil
        }
        self.siteTimezone = siteTimezone
        self.services = services
        self.siteID = siteID
        self.catalogSyncCoordinator = catalogSyncCoordinator
        self.isLocalCatalogEligible = isLocalCatalogEligible
        self.isBookingsEligible = isBookingsEligible
    }

    public var body: some View {
        Group {
            if let posModel {
                PointOfSaleDashboardView()
                    .environment(posModel)
                    .environment(posModel.paymentModel)
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
                barcodeScanService: barcodeScanService,
                receiptSender: receiptSender,
                siteID: siteID,
                catalogSyncCoordinator: catalogSyncCoordinator,
                isLocalCatalogEligible: isLocalCatalogEligible)
        }
        .environment(\.posAnalytics, services.analytics)
        .environment(\.posCurrencyProvider, services.currency)
        .environment(\.posFeatureFlags, services.featureFlags)
        .environment(\.posConnectivityProvider, services.connectivity)
        .environment(\.posExternalNavigation, services.externalNavigation)
        .environment(\.posExternalViews, services.externalViews)
        .environment(\.posBookingsEligible, isBookingsEligible)
        .environmentObject(posModalManager)
        .environmentObject(posSheetManager)
        .environmentObject(posCoverManager)
        .environment(orderListModel)
        .if(bookingsModel != nil) { view in
            view.environment(bookingsModel!)
        }
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
        bookingListFetchStrategyFactory: nil,
        isBookingsEligible: true,
        orderService: POSOrderServicePreview(),
        refundsService: POSRefundsServicePreview(),
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
        isLocalCatalogEligible: false,
        services: POSPreviewServices()
    )
}

#endif
