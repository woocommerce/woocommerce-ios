import XCTest
import Yosemite
import enum Storage.StatsVersion
import enum Networking.DotcomError
import enum Networking.NetworkError
@testable import WooCommerce


final class StorePerformanceViewModelTests: XCTestCase {

    @MainActor
    func test_dates_for_custom_range_are_correct_for_non_custom_time_range() throws {
        // Given
        let viewModel = StorePerformanceViewModel(siteID: 123, usageTracksEventEmitter: .init())

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
        mockSyncAllStats(with: stores, retrieveStatsError: DotcomError.noRestRoute)
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
}
