import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce
import enum Networking.DotcomError

final class AnalyticsHubViewModelTests: XCTestCase {

    private var stores: MockStoresManager!
    private var eventEmitter: StoreStatsUsageTracksEventEmitter!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var vm: AnalyticsHubViewModel!

    private let sampleSiteID: Int64 = 123
    private let sampleAdminURL = "https://example.com/wp-admin/"

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: .fake().copy(adminURL: sampleAdminURL)))
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
        ServiceLocator.setCurrencySettings(CurrencySettings()) // Default is US
        vm = createViewModel()
    }

    func test_cards_viewmodels_show_correct_data_after_updating_from_network() async {
        // Given
        let storage = MockStorageManager()
        insertActivePlugins([SitePlugin.SupportedPlugin.WCProductBundles.first,
                             SitePlugin.SupportedPlugin.WCGiftCards.first],
                            to: storage)
        let vm = createViewModel(storage: storage)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
                completion(.success(stats))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                completion(.success(topEarners))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                let siteStats = SiteSummaryStats.fake().copy(visitors: 30, views: 53)
                completion(.success(siteStats))
            case let .retrieveProductBundleStats(_, _, _, _, _, _, _, completion):
                let bundleStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 3))
                completion(.success(bundleStats))
            case let .retrieveTopProductBundles(_, _, _, _, _, completion):
                let topBundle = ProductsReportItem.fake()
                completion(.success([topBundle]))
            case let .retrieveUsedGiftCardStats(_, _, _, _, _, _, _, completion):
                let giftCardStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 20))
                completion(.success(giftCardStats))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertFalse(vm.revenueCard.isRedacted)
        XCTAssertFalse(vm.ordersCard.isRedacted)
        XCTAssertFalse(vm.productsStatsCard.isRedacted)
        XCTAssertFalse(vm.itemsSoldCard.isRedacted)
        XCTAssertFalse(vm.sessionsCard.isRedacted)
        XCTAssertFalse(vm.bundlesCard.isRedacted)
        XCTAssertFalse(vm.giftCardsCard.isRedacted)

        XCTAssertEqual(vm.revenueCard.leadingValue, "$62")
        XCTAssertEqual(vm.ordersCard.leadingValue, "15")
        XCTAssertEqual(vm.productsStatsCard.itemsSold, "5")
        XCTAssertEqual(vm.itemsSoldCard.itemsSoldData.count, 1)
        XCTAssertEqual(vm.sessionsCard.leadingValue, "53")
        XCTAssertEqual(vm.bundlesCard.bundlesSold, "3")
        XCTAssertEqual(vm.bundlesCard.bundlesSoldData.count, 1)
        XCTAssertEqual(vm.giftCardsCard.leadingValue, "20")
    }

    func test_cards_viewmodels_redacted_while_updating_from_network() async {
        // Given
        var loadingRevenueCardRedacted: Bool = false
        var loadingOrdersCardRedacted: Bool = false
        var loadingProductsStatsCardRedacted: Bool = false
        var loadingItemsSoldCardRedacted: Bool = false
        var loadingSessionsCardRedacted: Bool = false
        var loadingBundlesStatsCardRedacted: Bool = false
        var loadingBundlesSoldCardRedacted: Bool = false
        var loadingGiftCardsCardRedacted: Bool = false
        let storage = MockStorageManager()
        insertActivePlugins([SitePlugin.SupportedPlugin.WCProductBundles.first,
                             SitePlugin.SupportedPlugin.WCGiftCards.first],
                            to: storage)
        let vm = createViewModel(storage: storage)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
                loadingRevenueCardRedacted = vm.revenueCard.isRedacted
                loadingOrdersCardRedacted = vm.ordersCard.isRedacted
                loadingProductsStatsCardRedacted = vm.productsStatsCard.isRedacted
                completion(.success(stats))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                loadingItemsSoldCardRedacted = vm.itemsSoldCard.isRedacted
                completion(.success(topEarners))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                let siteStats = SiteSummaryStats.fake()
                loadingSessionsCardRedacted = vm.sessionsCard.isRedacted
                completion(.success(siteStats))
            case let .retrieveProductBundleStats(_, _, _, _, _, _, _, completion):
                let bundleStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 3))
                loadingBundlesStatsCardRedacted = vm.bundlesCard.isRedacted
                completion(.success(bundleStats))
            case let .retrieveTopProductBundles(_, _, _, _, _, completion):
                let topBundle = ProductsReportItem.fake()
                loadingBundlesSoldCardRedacted = vm.bundlesCard.isRedacted
                completion(.success([topBundle]))
            case let .retrieveUsedGiftCardStats(_, _, _, _, _, _, _, completion):
                let giftCardStats = GiftCardStats.fake()
                loadingGiftCardsCardRedacted = vm.giftCardsCard.isRedacted
                completion(.success(giftCardStats))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertTrue(loadingRevenueCardRedacted)
        XCTAssertTrue(loadingOrdersCardRedacted)
        XCTAssertTrue(loadingProductsStatsCardRedacted)
        XCTAssertTrue(loadingItemsSoldCardRedacted)
        XCTAssertTrue(loadingSessionsCardRedacted)
        XCTAssertTrue(loadingBundlesStatsCardRedacted)
        XCTAssertTrue(loadingBundlesSoldCardRedacted)
        XCTAssertTrue(loadingGiftCardsCardRedacted)
    }

    func test_bundles_card_shows_correct_loading_state_and_data_with_network_update() {
        // Given
    }

    func test_session_card_is_hidden_for_sites_without_jetpack_plugin() {
        // Given
        let storesForNonJetpackSite = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: .fake().copy(siteID: -1)))
        let vmNonJetpackSite = createViewModel(stores: storesForNonJetpackSite)

        let storesForJCPSite = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                              defaultSite: .fake().copy(isJetpackThePluginInstalled: false,
                                                                                                        isJetpackConnected: true)))
        let vmJCPSite = createViewModel(stores: storesForJCPSite)

        // Then
        XCTAssertFalse(vmNonJetpackSite.enabledCards.contains(.sessions))
        XCTAssertFalse(vmJCPSite.enabledCards.contains(.sessions))
    }

    @MainActor
    func test_session_card_is_hidden_for_shop_manager_when_stats_module_disabled() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultRoles: [.shopManager]))
        let vm = createViewModel(stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(SiteStatsStoreError.statsModuleDisabled))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertFalse(vm.enabledCards.contains(.sessions))
    }

    func test_time_range_card_tracks_expected_events() throws {
        // When
        vm.timeRangeCard.onTapped()
        vm.timeRangeCard.onSelected(.weekToDate)

        // Then
        assertEqual(["analytics_hub_date_range_button_tapped", "analytics_hub_date_range_option_selected"], analyticsProvider.receivedEvents)
        let optionSelectedEventProperty = try XCTUnwrap(analyticsProvider.receivedProperties.last?["option"] as? String)
        assertEqual("Week to Date", optionSelectedEventProperty)
    }

    func test_retrieving_stats_tracks_expected_waiting_time_event() async {
        // Given
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.success(.fake()))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.analyticsHubWaitingTimeLoaded.rawValue))
    }

    // MARK: Customized Analytics

    func test_enabledCards_shows_correct_data_after_loading_from_storage() async {
        // Given
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .orders, enabled: false),
                            AnalyticsCard(type: .products, enabled: false),
                            AnalyticsCard(type: .sessions, enabled: false)])
            default:
                break
            }
        }

        // When
        await vm.loadAnalyticsCardSettings()

        // Then
        assertEqual([.revenue], vm.enabledCards)
    }

    func test_enabledCards_contains_new_cards_not_in_stored_customizations_when_extensions_are_active() async {
        // Given
        let storage = MockStorageManager()
        insertActivePlugins([SitePlugin.SupportedPlugin.WCProductBundles.first, SitePlugin.SupportedPlugin.WCGiftCards.first], to: storage)
        let vm = createViewModel(storage: storage)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .orders, enabled: true),
                            AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .products, enabled: false),
                            AnalyticsCard(type: .sessions, enabled: false)])
            default:
                break
            }
        }

        // When
        await vm.loadAnalyticsCardSettings()

        // Then
        assertEqual([.orders, .revenue, .bundles, .giftCards], vm.enabledCards)
    }

    func test_it_updates_enabledCards_when_saved() async throws {
        // Given
        assertEqual([.revenue, .orders, .products, .sessions], vm.enabledCards)

        // When
        vm.customizeAnalytics()
        let customizeAnalytics = try XCTUnwrap(vm.customizeAnalyticsViewModel)
        customizeAnalytics.selectedCards = [AnalyticsCard(type: .revenue, enabled: true)]
        customizeAnalytics.saveChanges()

        // Then
        assertEqual([.revenue], vm.enabledCards)
    }

    func test_it_stores_updated_analytics_cards_when_saved() async throws {
        // When
        let storedAnalyticsCards = try waitFor { promise in
            self.stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
                switch action {
                case let .setAnalyticsHubCards(_, cards):
                    promise(cards)
                default:
                    break
                }
            }

            // Only revenue card is selected and changes are saved
            self.vm.customizeAnalytics()
            let customizeAnalytics = try XCTUnwrap(self.vm.customizeAnalyticsViewModel)
            customizeAnalytics.selectedCards = [AnalyticsCard(type: .revenue, enabled: true)]
            customizeAnalytics.saveChanges()
        }

        // Then
        // Stored cards contain updated selection
        let expectedCards = [AnalyticsCard(type: .revenue, enabled: true),
                             AnalyticsCard(type: .orders, enabled: false),
                             AnalyticsCard(type: .products, enabled: false),
                             AnalyticsCard(type: .sessions, enabled: false),
                             AnalyticsCard(type: .bundles, enabled: true),
                             AnalyticsCard(type: .giftCards, enabled: true),
                             AnalyticsCard(type: .googleCampaigns, enabled: true)]
        assertEqual(expectedCards, storedAnalyticsCards)
    }

    @MainActor
    func test_retrieving_stats_skips_summary_stats_request_when_sessions_card_is_hidden() async {
        // Given
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                XCTFail("Request to retrieve site summary stats should not be dispatched when sessions card is hidden")
                completion(.failure(DotcomError.unknown(code: "unknown_blog", message: "Unknown blog")))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .orders, enabled: true),
                            AnalyticsCard(type: .products, enabled: true),
                            AnalyticsCard(type: .sessions, enabled: false)])
            default:
                break
            }
        }

        // When
        await vm.loadAnalyticsCardSettings()
        await vm.updateData()
    }

    @MainActor
    func test_retrieving_stats_skips_top_earner_stats_request_when_products_card_is_hidden() async {
        // Given
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                XCTFail("Request to retrieve site summary stats should not be dispatched for sites without Jetpack")
                completion(.failure(DotcomError.unknown(code: "unknown_blog", message: "Unknown blog")))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.success(.fake()))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .orders, enabled: true),
                            AnalyticsCard(type: .products, enabled: false),
                            AnalyticsCard(type: .sessions, enabled: true)])
            default:
                break
            }
        }

        // When
        await vm.loadAnalyticsCardSettings()
        await vm.updateData()
    }

    func test_enabling_new_card_fetches_required_data() async throws {
        // Given it fetches order stats (current and previous) for initial cards
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .orders, enabled: true),
                            AnalyticsCard(type: .products, enabled: false),
                            AnalyticsCard(type: .sessions, enabled: false),
                            AnalyticsCard(type: .bundles, enabled: false),
                            AnalyticsCard(type: .giftCards, enabled: false)])
            default:
                break
            }
        }
        await vm.loadAnalyticsCardSettings()
        await vm.updateData()
        assertEqual(2, stores.receivedActions.filter { $0 is StatsActionV4 }.count)

        // When the products card is enabled
        let fetchedTopEarnerStats: Bool = try waitFor { promise in
            self.stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
                switch action {
                case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                    completion(.success(.fake()))
                case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                    completion(.success(.fake()))
                    promise(true)
                default:
                    break
                }
            }
            self.vm.customizeAnalytics()
            let customizeAnalytics = try XCTUnwrap(self.vm.customizeAnalyticsViewModel)
            customizeAnalytics.selectedCards.update(with: AnalyticsCard(type: .products, enabled: false))
            customizeAnalytics.saveChanges()
        }

        // Then it fetches order stats and top earner stats for products card
        XCTAssertTrue(fetchedTopEarnerStats)
        assertEqual(5, stores.receivedActions.filter { $0 is StatsActionV4 }.count)
    }

    func test_changing_card_settings_without_enabling_new_cards_does_not_update_data() async throws {
        // Given
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion([AnalyticsCard(type: .revenue, enabled: true),
                            AnalyticsCard(type: .orders, enabled: true),
                            AnalyticsCard(type: .products, enabled: false),
                            AnalyticsCard(type: .sessions, enabled: false),
                            AnalyticsCard(type: .bundles, enabled: false),
                            AnalyticsCard(type: .giftCards, enabled: false)])
            default:
                break
            }
        }
        await vm.loadAnalyticsCardSettings()

        // When & Then
        stores.whenReceivingAction(ofType: StatsActionV4.self) { _ in
            XCTFail("No data should be requested if new cards aren't enabled")
        }

        // Orders card is deselected and changes are saved
        self.vm.customizeAnalytics()
        let customizeAnalytics = try XCTUnwrap(self.vm.customizeAnalyticsViewModel)
        customizeAnalytics.selectedCards = [AnalyticsCard(type: .revenue, enabled: true)]
        customizeAnalytics.saveChanges()
    }

    func test_sessions_card_is_inactive_in_customizeAnalytics_when_ineligible() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: .fake().copy(siteID: -1)))
        let vm = createViewModel(stores: stores)

        // When
        vm.customizeAnalytics()

        // Then
        let customizeAnalyticsVM = try XCTUnwrap(vm.customizeAnalyticsViewModel)
        XCTAssertFalse(vm.enabledCards.contains(.sessions))
        XCTAssertTrue(customizeAnalyticsVM.inactiveCards.contains(where: { $0.type == .sessions }))
    }

    func test_bundles_card_is_inactive_in_customizeAnalytics_when_extension_is_inactive() throws {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCProductBundles.first,
                                                                            active: false))
        let vm = createViewModel(storage: storage)

        // When
        vm.customizeAnalytics()

        // Then
        let customizeAnalyticsVM = try XCTUnwrap(vm.customizeAnalyticsViewModel)
        XCTAssertFalse(vm.enabledCards.contains(.bundles))
        XCTAssertTrue(customizeAnalyticsVM.inactiveCards.contains(where: { $0.type == .bundles }))
    }

    func test_gift_cards_card_is_inactive_in_customizeAnalytics_when_extension_is_inactive() throws {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCGiftCards.first,
                                                                            active: false))
        let vm = createViewModel(storage: storage)

        // When
        vm.customizeAnalytics()

        // Then
        let customizeAnalyticsVM = try XCTUnwrap(vm.customizeAnalyticsViewModel)
        XCTAssertFalse(vm.enabledCards.contains(.giftCards))
        XCTAssertTrue(customizeAnalyticsVM.inactiveCards.contains(where: { $0.type == .giftCards }))
    }

    func test_customizeAnalytics_tracks_expected_event() {
        // When
        vm.customizeAnalytics()

        // Then
        XCTAssert(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.analyticsHubSettingsOpened.rawValue))
    }

    func test_product_bundles_card_displayed_when_plugin_active() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCProductBundles.first,
                                                                            active: true))
        let vm = createViewModel(storage: storage)

        // Then
        XCTAssertTrue(vm.enabledCards.contains(.bundles))
    }

    func test_product_bundles_card_not_displayed_when_plugin_inactive() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCProductBundles.first,
                                                                            active: false))
        let vm = createViewModel(storage: storage)

        // Then
        XCTAssertFalse(vm.enabledCards.contains(.bundles))
    }

    func test_gift_cards_card_displayed_when_plugin_active() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCGiftCards.first,
                                                                            active: true))
        let vm = createViewModel(storage: storage)

        // Then
        XCTAssertTrue(vm.enabledCards.contains(.giftCards))
    }

    func test_gift_cards_card_not_displayed_when_plugin_inactive() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.WCGiftCards.first,
                                                                            active: false))
        let vm = createViewModel(storage: storage)

        // Then
        XCTAssertFalse(vm.enabledCards.contains(.giftCards))
    }

    @MainActor
    func test_google_campaigns_card_not_displayed_when_plugin_inactive() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                            name: SitePlugin.SupportedPlugin.GoogleForWooCommerce.first,
                                                                            active: false))

        // When
        let vm = createViewModel(storage: storage)

        // Then
        XCTAssertFalse(vm.enabledCards.contains(.googleCampaigns))
    }
}

private extension AnalyticsHubViewModelTests {
    func createViewModel(stores: MockStoresManager? = nil, storage: MockStorageManager? = nil) -> AnalyticsHubViewModel {
        AnalyticsHubViewModel(siteID: sampleSiteID,
                              statsTimeRange: .thisMonth,
                              usageTracksEventEmitter: eventEmitter,
                              stores: stores ?? self.stores,
                              storage: storage ?? MockStorageManager(),
                              analytics: analytics)
    }

    func insertActivePlugins(_ pluginNames: [String?], to storage: MockStorageManager) {
        pluginNames.forEach { pluginName in
            storage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID, name: pluginName, active: true))
        }
    }
}
