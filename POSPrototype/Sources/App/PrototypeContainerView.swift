import SwiftUI
import PointOfSale
import Yosemite

struct PrototypeContainerView: View {
    let scenario: any POSPrototypeScenario

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let config = scenario.makeMockConfiguration()
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
                cardPresentPaymentService: StatefulPaymentService(configuration: config),
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

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .padding(16)
            }
        }
    }
}
