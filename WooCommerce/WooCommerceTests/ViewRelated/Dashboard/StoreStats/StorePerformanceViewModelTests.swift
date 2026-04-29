import XCTest
import Yosemite
import enum Storage.StatsVersion
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import enum Networking.DotcomError
import enum Networking.NetworkError
import YosemiteTestHelpers
@testable import WooCommerce


final class StorePerformanceViewModelTests: XCTestCase {
    private var storageManager: MockStorageManager!
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_dates_for_custom_range_are_correct_for_non_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, siteTimezone: .current, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisWeek)

        // Then
        let now = Date()
        let startDateForCustomRange = viewModel.startDateForCustomRange
        let endDateForCustomRange = viewModel.endDateForCustomRange
        XCTAssertTrue(now.isSameDay(as: endDateForCustomRange))
        XCTAssertTrue(try XCTUnwrap(now.adding(days: -30)).isSameDay(as: startDateForCustomRange))
    }

    @MainActor
    func test_dates_for_custom_range_are_correct_for_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        let startDate = try XCTUnwrap(Date().adding(days: -100))
        let endDate = try XCTUnwrap(Date().adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))

        // Then
        XCTAssertEqual(viewModel.startDateForCustomRange, startDate)
        XCTAssertEqual(viewModel.endDateForCustomRange, endDate)
    }

    @MainActor
    func test_granularityText_is_nil_for_non_custom_time_range() {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisWeek)

        // Then
        XCTAssertNil(viewModel.granularityText)
    }

    @MainActor
    func test_granularityText_is_not_nil_for_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        let startDate = try XCTUnwrap(Date().adding(days: -100))
        let endDate = try XCTUnwrap(Date().adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))

        // Then
        XCTAssertNotNil(viewModel.granularityText)
    }

    @MainActor
    func test_loadLastTimeRange_is_fetched_upon_initialization() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadLastSelectedPerformanceTimeRange(_, onCompletion):
                onCompletion(StatsTimeRangeV4.thisWeek)
            default:
                break
            }
        }

        // When
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())

        // Then
        XCTAssertEqual(viewModel.timeRange, .today) // initial value
        waitUntil {
            viewModel.timeRange == .thisWeek
        }
    }

    @MainActor
    func test_saveLastTimeRange_is_triggered_when_updating_time_range() {
        // Given
        var savedTimeRange: StatsTimeRangeV4?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setLastSelectedPerformanceTimeRange(_, timeRange):
                savedTimeRange = timeRange
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectTimeRange(.thisYear)

        // Then
        XCTAssertEqual(savedTimeRange, .thisYear)
    }

    @MainActor
    func test_shouldHighlightStats_is_updated_correctly() {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

        // When
        viewModel.didSelectStatsInterval(at: 1)

        // Then
        waitUntil {
            viewModel.shouldHighlightStats == true
        }

        // When
        viewModel.didSelectStatsInterval(at: nil)

        // Then
        waitUntil {
            viewModel.shouldHighlightStats == false
        }

        // When
        viewModel.didSelectStatsInterval(at: 2)

        // Then
        waitUntil {
            viewModel.shouldHighlightStats == true
        }

        // When
        viewModel.didSelectTimeRange(.thisMonth)

        // Then
        waitUntil {
            viewModel.shouldHighlightStats == false
        }
    }

    @MainActor
    func test_analyticsEnabled_is_updated_correctly_when_sync_stats_failed_with_noRestRoute_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores, retrieveStatsError: DotcomError.noRestRoute())
        XCTAssertTrue(viewModel.analyticsEnabled) // Initial value

        // When
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    @MainActor
    func test_analyticsEnabled_is_updated_correctly_when_sync_stats_failed_with_notFound_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores, retrieveStatsError: NetworkError.notFound(response: nil))
        XCTAssertTrue(viewModel.analyticsEnabled) // Initial value

        // When
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertFalse(viewModel.analyticsEnabled)
    }

    @MainActor
    func test_siteVisitStatMode_is_default_if_syncing_stats_succeeds_for_non_custom_time_range() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores)

        // When
        viewModel.didSelectTimeRange(.thisMonth)
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .default)
    }

    @MainActor
    func test_siteVisitStatMode_is_default_if_syncing_stats_succeeds_with_custom_time_range_of_same_day_for_jetpack_site() async throws {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: true,
                                           isJetpackConnected: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores)

        // When
        let endDate = Date().endOfDay(timezone: .current)
        let startDate = Date().startOfDay(timezone: .current)
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .default)
    }

    @MainActor
    func test_siteVisitStatMode_is_redactedDueToCustomRange_if_syncing_stats_succeeds_with_custom_time_range_longer_than_1_day_for_jetpack_site() async throws {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: true,
                                           isJetpackConnected: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores)

        // When
        let endDate = Date()
        let startDate = try XCTUnwrap(endDate.adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .redactedDueToCustomRange)
    }

    @MainActor
    func test_siteVisitStatMode_is_redactedDueToJetpack_if_syncing_stats_succeeds_with_custom_time_range_for_jcp_site() async throws {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: false,
                                           isJetpackConnected: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores)

        // When
        let endDate = Date()
        let startDate = try XCTUnwrap(endDate.adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .redactedDueToJetpack)
    }

    @MainActor
    func test_siteVisitStatMode_is_hidden_if_syncing_stats_succeeds_with_custom_time_range_for_non_jetpack_site() async throws {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: false,
                                           isJetpackConnected: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores)

        // When
        let endDate = Date()
        let startDate = try XCTUnwrap(endDate.adding(days: -10))
        viewModel.didSelectTimeRange(.custom(from: startDate, to: endDate))
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .hidden)
    }

    @MainActor
    func test_siteVisitStatMode_is_hidden_if_syncing_stats_failed_with_noPermission_error() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores, visitorStatsError: SiteStatsStoreError.noPermission)

        // When
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .hidden)
    }

    @MainActor
    func test_siteVisitStatMode_is_hidden_if_syncing_stats_failed_with_statsModuleDisabled_error_for_non_JCP_site() async {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: false,
                                           isJetpackConnected: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores, visitorStatsError: SiteStatsStoreError.statsModuleDisabled)

        // When
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .hidden)
    }

    @MainActor
    func test_siteVisitStatMode_is_redactedDueToJetpack_if_syncing_stats_failed_with_statsModuleDisabled_error_for_JCP_site() async {
        // Given
        let defaultSite = Site.fake().copy(isJetpackThePluginInstalled: false,
                                           isJetpackConnected: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: defaultSite))
        let viewModel = StorePerformanceViewModel(siteID: 123, stores: stores, usageTracksEventEmitter: .init())
        mockSyncAllStats(with: stores, visitorStatsError: SiteStatsStoreError.statsModuleDisabled)

        // When
        await viewModel.reloadDataIfNeeded(forceRefresh: true)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .redactedDueToJetpack)
    }

    @MainActor
    func test_hideStorePerformance_triggers_onDismiss() {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())
        var onDismissTriggered = false
        viewModel.onDismiss = {
            onDismissTriggered = true
        }

        // When
        viewModel.hideStorePerformance()

        // Then
        XCTAssertTrue(onDismissTriggered)
    }

    @MainActor
    func test_hideStorePerformance_triggers_tracking_event() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init(), analytics: analytics)

        // When
        viewModel.hideStorePerformance()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dynamic_dashboard_hide_card_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "performance")
    }

    // MARK: - Order type bottom sheet

    @MainActor
    func test_orderType_when_cached_SiteSetting_exists_then_seeded_synchronously_on_init() {
        // Given — a previously persisted analytics order date type for this site.
        let cachedSetting = SiteSetting.fake().copy(siteID: 123,
                                                    settingID: "woocommerce_date_type",
                                                    value: AnalyticsOrderDateType.allOrders.rawValue,
                                                    settingGroupKey: "wc_admin")
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: cachedSetting)
        let stores = MockStoresManager(sessionManager: .makeForTesting())

        // When
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // Then — the cached value seeds `orderType` synchronously, before any network round-trip.
        XCTAssertEqual(viewModel.orderType, .allOrders)
    }

    @MainActor
    func test_orderType_when_loadOrderType_succeeds_then_value_is_published() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsOrderDateType(_, onCompletion):
                onCompletion(.success(.completed))
            default:
                break
            }
        }

        // When
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // Then
        XCTAssertEqual(viewModel.orderType, .paid) // initial fallback (no cached SiteSetting)
        waitUntil {
            viewModel.orderType == .completed
        }
    }

    @MainActor
    func test_orderType_when_loadOrderType_fails_then_value_falls_back_to_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveAnalyticsOrderDateType(_, onCompletion):
                onCompletion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500)))
            default:
                break
            }
        }

        // When
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // Then — orderType remains the default `.paid` after failed fetch
        XCTAssertEqual(viewModel.orderType, .paid)
    }

    @MainActor
    func test_handleOrderTypeSelection_when_value_matches_current_then_no_action_dispatched_and_returns_true() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var updateActionDispatched = false
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case .updateAnalyticsOrderDateType:
                updateActionDispatched = true
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // When
        let shouldDismiss = await viewModel.handleOrderTypeSelection(.paid)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertFalse(updateActionDispatched)
        XCTAssertNil(viewModel.orderTypeUpdateError)
    }

    @MainActor
    func test_handleOrderTypeSelection_when_save_succeeds_then_orderType_is_updated_and_returns_true() async {
        // Given
        var receivedValue: AnalyticsOrderDateType?
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case let .updateAnalyticsOrderDateType(_, value, onCompletion):
                receivedValue = value
                onCompletion(.success(()))
            default:
                break
            }
        }
        // Stub stats actions so reloadDataIfNeeded(forceRefresh:) doesn't hang.
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // When
        let shouldDismiss = await viewModel.handleOrderTypeSelection(.completed)

        // Then
        XCTAssertTrue(shouldDismiss)
        XCTAssertEqual(receivedValue, .completed)
        XCTAssertEqual(viewModel.orderType, .completed)
        XCTAssertNil(viewModel.orderTypeUpdateError)
        XCTAssertNil(viewModel.updatingOrderType)
    }

    @MainActor
    func test_handleOrderTypeSelection_when_save_fails_then_error_is_set_and_returns_false() async {
        // Given
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 500)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case .updateAnalyticsOrderDateType(_, _, let onCompletion):
                onCompletion(.failure(expectedError))
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())

        // When
        let shouldDismiss = await viewModel.handleOrderTypeSelection(.allOrders)

        // Then
        XCTAssertFalse(shouldDismiss)
        XCTAssertEqual(viewModel.orderType, .paid)
        XCTAssertEqual(viewModel.orderTypeUpdateError as? NetworkError, expectedError)
        XCTAssertNil(viewModel.updatingOrderType)
    }

    @MainActor
    func test_handleOrderTypeSelection_while_save_is_in_flight_then_updatingOrderType_reflects_new_type() async {
        // Given — hold the update-action completion so the save suspends mid-flight.
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var pendingUpdateCompletion: ((Result<Void, Error>) -> Void)?
        let updateActionDispatched = expectation(description: "update action dispatched")
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case let .updateAnalyticsOrderDateType(_, _, onCompletion):
                pendingUpdateCompletion = onCompletion
                updateActionDispatched.fulfill()
            default:
                break
            }
        }
        // Stub stats actions so the post-save reload doesn't hang.
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init())
        XCTAssertNil(viewModel.updatingOrderType)

        // When — kick off the selection; it suspends waiting on `pendingUpdateCompletion`.
        let task = Task { @MainActor in
            await viewModel.handleOrderTypeSelection(.completed)
        }
        await fulfillment(of: [updateActionDispatched], timeout: 1)

        // Then — while the save is in flight, the in-flight type is exposed for the bottom sheet row spinner.
        XCTAssertEqual(viewModel.updatingOrderType, .completed)

        // Cleanup — release the suspended save and verify the in-flight state clears.
        pendingUpdateCompletion?(.success(()))
        _ = await task.value
        XCTAssertNil(viewModel.updatingOrderType)
    }

    @MainActor
    func test_handleOrderTypeSelection_when_save_succeeds_then_tracks_selected_event_with_type_and_option() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case .updateAnalyticsOrderDateType(_, _, let onCompletion):
                onCompletion(.success(()))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                onCompletion(.success(()))
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init(),
                                                  analytics: analytics)

        // When
        _ = await viewModel.handleOrderTypeSelection(.allOrders)

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dashboard_stats_order_date_type_selected" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "dashboard_stats")
        XCTAssertEqual(properties?["option"], "date_created")
    }

    @MainActor
    func test_handleOrderTypeSelection_when_save_fails_then_does_not_track_selected_event() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveAnalyticsOrderDateType(_, let onCompletion):
                onCompletion(.success(.paid))
            case .updateAnalyticsOrderDateType(_, _, let onCompletion):
                onCompletion(.failure(NetworkError.unacceptableStatusCode(statusCode: 500)))
            default:
                break
            }
        }
        let viewModel = StorePerformanceViewModel(siteID: 123,
                                                  stores: stores,
                                                  storageManager: storageManager,
                                                  usageTracksEventEmitter: .init(),
                                                  analytics: analytics)

        // When
        _ = await viewModel.handleOrderTypeSelection(.completed)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains("dashboard_stats_order_date_type_selected"))
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("dashboard_stats_order_date_type_update_failed"))
    }

    @MainActor
    func test_trackOrderDateTypeSelectorTapped_tracks_selector_event_with_type_property() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init(), analytics: analytics)

        // When
        viewModel.trackOrderDateTypeSelectorTapped()

        // Then
        let index = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "dashboard_stats_order_date_type_selector_tapped" }))
        let properties = analyticsProvider.receivedProperties[index] as? [String: AnyHashable]
        XCTAssertEqual(properties?["type"], "dashboard_stats")
    }

    @MainActor
    func test_given_existing_cached_data_when_timestamp_is_fresh_then_cached_data_is_shown() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let siteID: Int64 = 123
        let currentDate = Date()
        let dateFormatter = DateFormatter.Stats.statsDayFormatter
        let timeRange: StatsTimeRangeV4 = .today

        // Set up timestamp for .today time range since viewModel defaults to .today
        DashboardTimestampStore.saveTimestamp(currentDate,
                                            for: .performance,
                                            at: .today)

        let viewModel = StorePerformanceViewModel(
            siteID: siteID,
            stores: stores,
            storageManager: storageManager,
            usageTracksEventEmitter: .init()
        )

        // Populate sample data
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(siteID: siteID, items: [ .fake().copy(visitors: 17) ])
        insertSiteVisitStats(siteVisitStats, timeRange: timeRange)

        let orderStats = OrderStatsV4(siteID: siteID,
                                      granularity: .daily,
                                      totals: .fake().copy(totalOrders: 3, grossRevenue: 6220.7),
                                      intervals: [
                                          OrderStatsV4Interval(
                                              interval: dateFormatter.string(from: currentDate),
                                              dateStart: dateFormatter.string(from: currentDate) + " 00:00:00",
                                              dateEnd: dateFormatter.string(from: currentDate) + " 23:59:59",
                                              subtotals: OrderStatsV4Totals(
                                                  totalOrders: 3,
                                                  totalItemsSold: 5,
                                                  grossRevenue: 800,
                                                  netRevenue: 800,
                                                  averageOrderValue: 266
                                              )
                                          )
                                      ])
        insertOrderStats(orderStats, timeRange: timeRange)


        let dateString = StatsStoreV4.buildDateString(from: Date(), timeRange: .today)
        let siteSummaryStats = Yosemite.SiteSummaryStats.fake().copy(siteID: siteID, date: dateString, visitors: 22)
        insertSiteSummaryStats(siteSummaryStats, timeRange: timeRange)

        // When
        XCTAssertEqual(viewModel.siteVisitStatMode, .hidden)
        await viewModel.reloadDataIfNeeded(forceRefresh: false)

        // Then
        XCTAssertEqual(viewModel.siteVisitStatMode, .default) // Should be changed from `.hidden`

        // Cleanup
        DashboardTimestampStore.removeTimestamp(for: .performance, at: .today)
    }
}

// MARK: - Private helpers
//
private extension StorePerformanceViewModelTests {
    func mockSyncAllStats(with stores: MockStoresManager,
                          retrieveStatsError: Error? = nil,
                          visitorStatsError: Error? = nil,
                          siteSummaryStatsError: Error? = nil) {
        stores.whenReceivingAction(ofType: StatsActionV4.self) { action in
            switch action {
            case let .retrieveStats(_, _, _, _, _, _, _, onCompletion):
                if let retrieveStatsError {
                    onCompletion(.failure(retrieveStatsError))
                } else {
                    onCompletion(.success(()))
                }
            case let .retrieveSiteVisitStats(_, _, _, _, onCompletion):
                if let visitorStatsError {
                    onCompletion(.failure(visitorStatsError))
                } else {
                    onCompletion(.success(()))
                }
            case let .retrieveSiteSummaryStats(_, _, _, _, _, _, onCompletion):
                if let siteSummaryStatsError {
                    onCompletion(.failure(siteSummaryStatsError))
                } else {
                    onCompletion(.success(.fake()))
                }
            default:
                break
            }
        }
    }

    func insertOrderStats(_ readonlyOrderStats: Yosemite.OrderStatsV4, timeRange: StatsTimeRangeV4) {
        let storageOrderStats = storage.insertNewObject(ofType: StorageOrderStatsV4.self)
        storageOrderStats.timeRange = timeRange.rawValue
        storageOrderStats.totals = storage.insertNewObject(ofType: StorageOrderStatsV4Totals.self)
        storageOrderStats.update(with: readonlyOrderStats)
        readonlyOrderStats.intervals.forEach { readOnlyInterval in
            let newStorageInterval = storage.insertNewObject(ofType: StorageOrderStatsV4Interval.self)
            newStorageInterval.subtotals = storage.insertNewObject(ofType: StorageOrderStatsV4Totals.self)
            newStorageInterval.update(with: readOnlyInterval)
            storageOrderStats.addToIntervals(newStorageInterval)
        }
        storage.saveIfNeeded()
    }

    func insertSiteVisitStats(_ readonlySiteVisitStats: Yosemite.SiteVisitStats, timeRange: StatsTimeRangeV4) {
        let storageSiteVisitStats = storage.insertNewObject(ofType: StorageSiteVisitStats.self)
        storageSiteVisitStats.timeRange = timeRange.rawValue
        storageSiteVisitStats.update(with: readonlySiteVisitStats)
        readonlySiteVisitStats.items?.forEach { readOnlyItem in
            let newStorageItem = storage.insertNewObject(ofType: StorageSiteVisitStatsItem.self)
            newStorageItem.update(with: readOnlyItem)
            storageSiteVisitStats.addToItems(newStorageItem)
        }
        storage.saveIfNeeded()
    }

    func insertSiteSummaryStats(_ readOnlySiteSummaryStats: Yosemite.SiteSummaryStats, timeRange: StatsTimeRangeV4) {
        let storageSiteSummaryStats = storage.insertNewObject(ofType: StorageSiteSummaryStats.self)
        storageSiteSummaryStats.period = timeRange.summaryStatsGranularity.rawValue
        storageSiteSummaryStats.update(with: readOnlySiteSummaryStats)
        storage.saveIfNeeded()
    }
}
