import Testing
@testable import PointOfSale
@testable import Storage

@MainActor
struct PointOfSaleEntryPointAnalyticsTests {
    @Test(arguments: [
        Selection(eligible: false, hasDatabase: true, hasCoordinator: true, expected: .remote),
        Selection(eligible: true, hasDatabase: true, hasCoordinator: true, expected: .localCatalog),
        Selection(eligible: true, hasDatabase: false, hasCoordinator: true, expected: .remote),
        Selection(eligible: true, hasDatabase: true, hasCoordinator: false, expected: .remote)
    ])
    func test_entry_point_when_catalog_controller_is_selected_then_tracks_actual_strategy(selection: Selection) throws {
        // Given
        let tracker = MockPOSCollectOrderPaymentAnalyticsTracker()
        let database = selection.hasDatabase ? try GRDBManager() : nil
        let coordinator = selection.hasCoordinator ? MockPOSCatalogSyncCoordinator() : nil

        // When
        _ = PointOfSaleEntryPointView(
            siteID: 1,
            itemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
            popularItemFetchStrategyFactory: PointOfSaleItemFetchStrategyFactoryPreview(),
            couponProvider: PointOfSaleCouponServicePreview(),
            couponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryPreview(),
            orderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryPreview(),
            orderService: POSOrderServicePreview(),
            refundsService: POSRefundsServicePreview(),
            refundSubmissionProcessor: POSNoOpRefundSubmissionProcessor(),
            onPointOfSaleModeActiveStateChange: { _ in },
            cardPresentPaymentService: CardPresentPaymentPreviewService(),
            receiptService: POSReceiptServicePreview(),
            pluginsService: PluginsServicePreview(),
            settingsService: PointOfSaleSettingsServicePreview(),
            collectOrderPaymentAnalyticsTracker: tracker,
            searchHistoryService: PointOfSalePreviewHistoryService(),
            barcodeScanService: PointOfSalePreviewBarcodeScanService(),
            posEligibilityChecker: PointOfSalePreviewTabEligibilityChecker(),
            defaultSiteName: "Test Store",
            siteSettings: [],
            grdbManager: database,
            catalogSyncCoordinator: coordinator,
            isLocalCatalogEligible: selection.eligible,
            receiptSettingsAdminURL: "",
            staffFetcher: MockPOSStaffFetcher(),
            services: POSPreviewServices()
        )

        // Then
        #expect(tracker.catalogSyncStrategy == selection.expected)
    }

    struct Selection {
        let eligible: Bool
        let hasDatabase: Bool
        let hasCoordinator: Bool
        let expected: POSCheckoutCatalogStrategy
    }
}
