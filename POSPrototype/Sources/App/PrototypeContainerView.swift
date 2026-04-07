import SwiftUI
import Inject
import PointOfSale
import Yosemite

struct PrototypeContainerView: View {
    let scenario: any POSPrototypeScenario
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let config = scenario.makeMockConfiguration()
        PrototypeContainerContent(
            config: config,
            onDismiss: { dismiss() }
        )
    }
}

/// Inner view that owns the payment service via @State so there's
/// exactly one instance shared between POS views and the control panel.
private struct PrototypeContainerContent: View {
    let config: MockConfiguration
    let onDismiss: () -> Void
    @ObserveInjection var inject

    @State private var paymentService: StatefulPaymentService

    init(config: MockConfiguration, onDismiss: @escaping () -> Void) {
        self.config = config
        self.onDismiss = onDismiss
        self._paymentService = State(initialValue: StatefulPaymentService(configuration: config))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            PointOfSaleEntryPointView(
                siteID: 1,
                itemFetchStrategyFactory: PrototypeItemFetchStrategyFactory(products: config.products),
                popularItemFetchStrategyFactory: PrototypeItemFetchStrategyFactory(products: []),
                couponProvider: PrototypeCouponService(),
                couponFetchStrategyFactory: PrototypeCouponFetchStrategyFactory(),
                orderListFetchStrategyFactory: PrototypeOrderListFetchStrategyFactory(),
                bookingListFetchStrategyFactory: PrototypeBookingListFetchStrategyFactory(),
                isBookingsEligible: config.isBookingsEligible,
                orderService: StatefulOrderService(configuration: config),
                refundsService: PrototypeRefundsService(),
                onPointOfSaleModeActiveStateChange: { _ in },
                cardPresentPaymentService: paymentService,
                receiptService: PrototypeReceiptService(),
                pluginsService: PrototypePluginsService(),
                settingsService: PrototypeSettingsService(storeName: config.storeName),
                collectOrderPaymentAnalyticsTracker: PrototypeCollectOrderPaymentAnalytics(),
                searchHistoryService: PrototypeSearchHistoryProvider(),
                barcodeScanService: PrototypeBarcodeScanService(),
                posEligibilityChecker: PrototypeEntryPointEligibilityChecker(),
                siteTimezone: .current,
                defaultSiteName: config.storeName,
                siteSettings: [],
                grdbManager: nil,
                catalogSyncCoordinator: PrototypeCatalogSyncCoordinator(),
                isLocalCatalogEligible: false,
                services: PrototypeDependencyProvider(),
                itemProvider: StatefulItemService(configuration: config)
            )
        }
        .overlay(alignment: .bottom) {
            PrototypeControlPanel(paymentService: paymentService, onCloseScenario: onDismiss)
        }
        .enableInjection()
    }
}
