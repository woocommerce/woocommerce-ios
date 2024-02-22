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

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
        ServiceLocator.setCurrencySettings(CurrencySettings()) // Default is US
    }

    func test_cards_viewmodels_show_correct_data_after_updating_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)

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

        XCTAssertEqual(vm.revenueCard.leadingValue, "$62")
        XCTAssertEqual(vm.ordersCard.leadingValue, "15")
        XCTAssertEqual(vm.productsStatsCard.itemsSold, "5")
        XCTAssertEqual(vm.itemsSoldCard.itemsSoldData.count, 1)
        XCTAssertEqual(vm.sessionsCard.leadingValue, "53")
        XCTAssertEqual(vm.sessionsCard.trailingValue, "50%")
    }

    func test_cards_viewmodels_show_sync_error_after_getting_error_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertTrue(vm.revenueCard.showSyncError)
        XCTAssertTrue(vm.ordersCard.showSyncError)
        XCTAssertTrue(vm.productsStatsCard.showStatsError)
        XCTAssertTrue(vm.itemsSoldCard.showItemsSoldError)
        XCTAssertTrue(vm.sessionsCard.showSyncError)
    }

    func test_cards_viewmodels_show_sync_error_only_if_underlying_request_fails() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                completion(.success(topEarners))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertTrue(vm.revenueCard.showSyncError)
        XCTAssertTrue(vm.ordersCard.showSyncError)
        XCTAssertTrue(vm.productsStatsCard.showStatsError)

        XCTAssertFalse(vm.itemsSoldCard.showItemsSoldError)
        XCTAssertEqual(vm.itemsSoldCard.itemsSoldData.count, 1)

        XCTAssertTrue(vm.sessionsCard.showSyncError)
    }

    func test_cards_viewmodels_redacted_while_updating_from_network() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)
        var loadingRevenueCard: AnalyticsReportCardViewModel?
        var loadingOrdersCard: AnalyticsReportCardViewModel?
        var loadingProductsCard: AnalyticsProductsStatsCardViewModel?
        var loadingItemsSoldCard: AnalyticsItemsSoldViewModel?
        var loadingSessionsCard: AnalyticsReportCardCurrentPeriodViewModel?
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                let stats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15, totalItemsSold: 5, grossRevenue: 62))
                loadingRevenueCard = vm.revenueCard
                loadingOrdersCard = vm.ordersCard
                loadingProductsCard = vm.productsStatsCard
                loadingItemsSoldCard = vm.itemsSoldCard
                completion(.success(stats))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                let topEarners = TopEarnerStats.fake().copy(items: [.fake()])
                completion(.success(topEarners))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                let siteStats = SiteSummaryStats.fake()
                loadingSessionsCard = vm.sessionsCard
                completion(.success(siteStats))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertEqual(loadingRevenueCard?.isRedacted, true)
        XCTAssertEqual(loadingOrdersCard?.isRedacted, true)
        XCTAssertEqual(loadingProductsCard?.isRedacted, true)
        XCTAssertEqual(loadingItemsSoldCard?.isRedacted, true)
        XCTAssertEqual(loadingSessionsCard?.isRedacted, true)
    }

    func test_session_card_is_hidden_for_custom_range() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)
        XCTAssertTrue(vm.showSessionsCard)

        // When
        vm.timeRangeSelectionType = .custom(start: Date(), end: Date())

        // Then
        XCTAssertFalse(vm.showSessionsCard)

        // When
        vm.timeRangeSelectionType = .lastMonth

        // Then
        XCTAssertTrue(vm.showSessionsCard)
    }

    func test_session_card_is_hidden_for_sites_without_jetpack() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)

        // Then
        XCTAssertFalse(vm.showSessionsCard)
    }

    @MainActor
    func test_session_card_and_stats_CTA_are_hidden_for_shop_manager_when_stats_module_disabled() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultRoles: [.shopManager]))
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)
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
        XCTAssertFalse(vm.showJetpackStatsCTA)
        XCTAssertFalse(vm.showSessionsCard)
    }

    func test_time_range_card_tracks_expected_events() throws {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, analytics: analytics)

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
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores, analytics: analytics)
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

    @MainActor
    func test_retrieving_stats_skips_summary_stats_request_for_sites_without_jetpack() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                XCTFail("Request to retrieve site summary stats should not be dispatched for sites without Jetpack")
                completion(.failure(DotcomError.unknown(code: "unknown_blog", message: "Unknown blog")))
            default:
                break
            }
        }

        // When
        await vm.updateData()
    }

    @MainActor
    func test_showJetpackStatsCTA_true_for_admin_when_stats_module_disabled() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)
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
        XCTAssertFalse(vm.showJetpackStatsCTA)

        // When
        await vm.updateData()

        // Then
        XCTAssertTrue(vm.showJetpackStatsCTA)
    }

    @MainActor
    func test_showJetpackStatsCTA_false_for_admin_when_stats_request_fails_and_stats_module_enabled() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores)
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.success(.fake()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertFalse(vm.showJetpackStatsCTA)
    }

    @MainActor
    func test_enableJetpackStats_hides_call_to_action_after_successfully_enabling_stats() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123,
                                       statsTimeRange: .today,
                                       usageTracksEventEmitter: eventEmitter,
                                       stores: stores,
                                       backendProcessingDelay: 0)
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.success(()))
            }
        }
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
        await vm.enableJetpackStats()

        // Then
        XCTAssertFalse(vm.showJetpackStatsCTA)
    }

    @MainActor
    func test_enableJetpackStats_shows_error_and_call_to_action_after_failing_to_enable_stats() async {
        // Given
        let noticePresenter = MockNoticePresenter()
        let vm = AnalyticsHubViewModel(siteID: 123,
                                       statsTimeRange: .today,
                                       usageTracksEventEmitter: eventEmitter,
                                       stores: stores,
                                       noticePresenter: noticePresenter,
                                       backendProcessingDelay: 0)
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            }
        }

        // When
        await vm.enableJetpackStats()

        // Then
        XCTAssertEqual(noticePresenter.queuedNotices.count, 1)
        XCTAssertTrue(vm.showJetpackStatsCTA)
    }

    func test_it_tracks_expected_jetpack_stats_CTA_success_events() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores, analytics: analytics)
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
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.success(()))
            }
        }

        // When
        await vm.updateData()
        await vm.enableJetpackStats()

        // Then
        let expectedEvents: [WooAnalyticsStat] = [
            .analyticsHubEnableJetpackStatsShown,
            .analyticsHubEnableJetpackStatsTapped,
            .analyticsHubEnableJetpackStatsSuccess
        ]
        for event in expectedEvents {
            XCTAssert(analyticsProvider.receivedEvents.contains(event.rawValue), "Did not receive expected event: \(event.rawValue)")
        }
    }

    func test_it_tracks_expected_jetpack_stats_CTA_failure_events() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .today, usageTracksEventEmitter: eventEmitter, stores: stores, analytics: analytics)
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
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            }
        }

        // When
        await vm.updateData()
        await vm.enableJetpackStats()

        // Then
        let expectedEvents: [WooAnalyticsStat] = [
            .analyticsHubEnableJetpackStatsShown,
            .analyticsHubEnableJetpackStatsTapped,
            .analyticsHubEnableJetpackStatsFailed
        ]
        for event in expectedEvents {
            XCTAssert(analyticsProvider.receivedEvents.contains(event.rawValue), "Did not receive expected event: \(event.rawValue)")
        }
    }

    @MainActor
    func test_cards_viewmodels_contain_expected_reportURL_elements() async throws {
        // Given
        let sampleAdminURL = "https://example.com/wp-admin/"
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(adminURL: sampleAdminURL)
        let stores = MockStoresManager(sessionManager: sessionManager)
        let vm = AnalyticsHubViewModel(siteID: 123,
                                       statsTimeRange: .thisMonth,
                                       usageTracksEventEmitter: eventEmitter,
                                       stores: stores)

        // When
        let revenueCardReportURL = try XCTUnwrap(vm.revenueCard.reportViewModel?.initialURL)
        let ordersCardReportURL = try XCTUnwrap(vm.ordersCard.reportViewModel?.initialURL)
        let productsCardReportURL = try XCTUnwrap(vm.productsStatsCard.reportViewModel?.initialURL)

        let revenueCardURLQueryItems = try XCTUnwrap(URLComponents(url: revenueCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)
        let ordersCardURLQueryItems = try XCTUnwrap(URLComponents(url: ordersCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)
        let productsCardURLQueryItems = try XCTUnwrap(URLComponents(url: productsCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Then
        // Report URL contains expected admin URL
        XCTAssertTrue(revenueCardReportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(ordersCardReportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(productsCardReportURL.relativeString.contains(sampleAdminURL))

        // Report URL contains expected report path
        XCTAssertTrue(revenueCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/revenue")))
        XCTAssertTrue(ordersCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/orders")))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/products")))

        // Report URL contains expected time range period
        let expectedPeriodQueryItem = URLQueryItem(name: "period", value: "month")
        XCTAssertTrue(revenueCardURLQueryItems.contains(expectedPeriodQueryItem))
        XCTAssertTrue(ordersCardURLQueryItems.contains(expectedPeriodQueryItem))
        XCTAssertTrue(productsCardURLQueryItems.contains(expectedPeriodQueryItem))
    }

    @MainActor
    func test_cards_viewmodels_contain_expected_report_path_after_updating_from_network() async throws {
        // Given
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(adminURL: "https://example.com/wp-admin/")
        let stores = MockStoresManager(sessionManager: sessionManager)
        let vm = AnalyticsHubViewModel(siteID: 123,
                                       statsTimeRange: .thisMonth,
                                       usageTracksEventEmitter: eventEmitter,
                                       stores: stores)

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
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        let revenueCardReportURL = try XCTUnwrap(vm.revenueCard.reportViewModel?.initialURL)
        let ordersCardReportURL = try XCTUnwrap(vm.ordersCard.reportViewModel?.initialURL)
        let productsCardReportURL = try XCTUnwrap(vm.productsStatsCard.reportViewModel?.initialURL)

        let revenueCardURLQueryItems = try XCTUnwrap(URLComponents(url: revenueCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)
        let ordersCardURLQueryItems = try XCTUnwrap(URLComponents(url: ordersCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)
        let productsCardURLQueryItems = try XCTUnwrap(URLComponents(url: productsCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Report URL contains expected report path
        XCTAssertTrue(revenueCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/revenue")))
        XCTAssertTrue(ordersCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/orders")))
        XCTAssertTrue(productsCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/products")))
    }

    @MainActor
    func test_cards_viewmodels_contain_non_nil_report_url_while_loading_and_after_error() async {
        // Given
        let sessionManager = SessionManager.testingInstance
        sessionManager.defaultSite = Site.fake().copy(adminURL: "https://example.com/wp-admin/")
        let stores = MockStoresManager(sessionManager: sessionManager)
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)

        var loadingRevenueCard: AnalyticsReportCardViewModel?
        var loadingOrdersCard: AnalyticsReportCardViewModel?
        var loadingProductsCard: AnalyticsProductsStatsCardViewModel?
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveCustomStats(_, _, _, _, _, _, _, completion):
                loadingRevenueCard = vm.revenueCard
                loadingOrdersCard = vm.ordersCard
                loadingProductsCard = vm.productsStatsCard
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveTopEarnerStats(_, _, _, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            default:
                break
            }
        }

        // When
        await vm.updateData()

        // Then
        XCTAssertNotNil(loadingRevenueCard?.reportViewModel?.initialURL)
        XCTAssertNotNil(loadingOrdersCard?.reportViewModel?.initialURL)
        XCTAssertNotNil(loadingProductsCard?.reportViewModel?.initialURL)

        XCTAssertNotNil(vm.revenueCard.reportViewModel?.initialURL)
        XCTAssertNotNil(vm.ordersCard.reportViewModel?.initialURL)
        XCTAssertNotNil(vm.productsStatsCard.reportViewModel?.initialURL)
    }

    func test_allCardsWithSettings_shows_correct_data_after_loading_from_storage() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)
        let expectedCards = [AnalyticsCard(type: .revenue, enabled: true),
                             AnalyticsCard(type: .orders, enabled: false),
                             AnalyticsCard(type: .products, enabled: false),
                             AnalyticsCard(type: .sessions, enabled: false)]
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadAnalyticsHubCards(_, completion):
                completion(expectedCards)
            default:
                break
            }
        }

        // When
        await vm.loadAnalyticsCardSettings()

        // Then
        assertEqual(expectedCards, vm.allCardsWithSettings)
    }

    func test_it_updates_allCardsWithSettings_when_saved() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)

        // When
        vm.customizeAnalyticsViewModel.selectedCards = [AnalyticsCard(type: .revenue, enabled: true)]
        vm.customizeAnalyticsViewModel.saveChanges()

        // Then
        let expectedCards = [AnalyticsCard(type: .revenue, enabled: true),
                             AnalyticsCard(type: .orders, enabled: false),
                             AnalyticsCard(type: .products, enabled: false),
                             AnalyticsCard(type: .sessions, enabled: false)]
        assertEqual(expectedCards, vm.allCardsWithSettings)
    }

    func test_it_stores_updated_analytics_cards_when_saved() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)

        // When
        let storedAnalyticsCards = waitFor { promise in
            self.stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
                switch action {
                case let .setAnalyticsHubCards(_, cards):
                    promise(cards)
                default:
                    break
                }
            }

            // Only revenue card is selected and changes are saved
            vm.customizeAnalyticsViewModel.selectedCards = [AnalyticsCard(type: .revenue, enabled: true)]
            vm.customizeAnalyticsViewModel.saveChanges()
        }

        // Then
        // Stored cards contain updated selection
        let expectedCards = [AnalyticsCard(type: .revenue, enabled: true),
                             AnalyticsCard(type: .orders, enabled: false),
                             AnalyticsCard(type: .products, enabled: false),
                             AnalyticsCard(type: .sessions, enabled: false)]
        assertEqual(expectedCards, storedAnalyticsCards)
    }

    func test_it_updates_customizeAnalyticsVM_when_analytics_cards_saved() async {
        // Given
        let vm = AnalyticsHubViewModel(siteID: 123, statsTimeRange: .thisMonth, usageTracksEventEmitter: eventEmitter, stores: stores)

        // When
        let storedAnalyticsCards = waitFor { promise in
            self.stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
                switch action {
                case let .setAnalyticsHubCards(_, cards):
                    promise(cards)
                default:
                    break
                }
            }

            // Only orders card is selected and changes are saved
            vm.customizeAnalyticsViewModel.selectedCards = [AnalyticsCard(type: .orders, enabled: true)]
            vm.customizeAnalyticsViewModel.saveChanges()
        }

        // Then
        // View model contains updated selection and order
        let expectedCards = [AnalyticsCard(type: .orders, enabled: true),
                             AnalyticsCard(type: .revenue, enabled: false),
                             AnalyticsCard(type: .products, enabled: false),
                             AnalyticsCard(type: .sessions, enabled: false)]
        assertEqual(expectedCards, vm.customizeAnalyticsViewModel.allCards)
    }
}
