import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class SessionsReportCardViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!
    private var noticePresenter: MockNoticePresenter!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        noticePresenter = MockNoticePresenter()
    }

    func test_it_inits_with_expected_values() {
        // Given
        let vm = SessionsReportCardViewModel(
            siteID: sampleSiteID,
            currentOrderStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 5)),
            siteStats: SiteSummaryStats.fake().copy(visitors: 10, views: 60),
            timeRange: .today,
            isJetpackStatsDisabled: false,
            isRedacted: false,
            updateSiteStatsData: {}
        )

        // Then
        assertEqual("60", vm.leadingValue)
        XCTAssertNil(vm.leadingDelta)
        assertEqual([], vm.leadingChartData)
        assertEqual("50%", vm.trailingValue)
        XCTAssertNil(vm.trailingDelta)
        assertEqual([], vm.trailingChartData)
        XCTAssertFalse(vm.isRedacted)
        XCTAssertFalse(vm.showSyncError)
        XCTAssertNil(vm.reportViewModel)
    }

    func test_it_shows_sync_error_when_current_stats_are_nil() {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: false,
                                             updateSiteStatsData: {})

        // Then
        XCTAssertTrue(vm.showSyncError)
    }

    func test_it_shows_sync_error_when_previous_stats_are_nil() {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: .fake(),
                                             siteStats: nil,
                                             timeRange: .today,
                                             isJetpackStatsDisabled: false,
                                             updateSiteStatsData: {})

        // Then
        XCTAssertTrue(vm.showSyncError)
    }

    func test_it_provides_expected_values_when_redacted() {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: nil,
                                             timeRange: .today,
                                             isJetpackStatsDisabled: false,
                                             isRedacted: true,
                                             updateSiteStatsData: {})

        // Then

        assertEqual("1000", vm.leadingValue)
        XCTAssertNil(vm.leadingDelta)
        assertEqual([], vm.leadingChartData)
        assertEqual("1000%", vm.trailingValue)
        XCTAssertNil(vm.trailingDelta)
        assertEqual([], vm.trailingChartData)
        XCTAssertTrue(vm.isRedacted)
        XCTAssertFalse(vm.showSyncError)
        XCTAssertNil(vm.reportViewModel)
    }

    // MARK: Sessions Data Availability

    func test_sessions_data_available_when_custom_time_range_not_selected() {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: nil,
                                             timeRange: .today,
                                             isJetpackStatsDisabled: false,
                                             updateSiteStatsData: {})

        // Then
        XCTAssertTrue(vm.isSessionsDataAvailable)
    }

    func test_sessions_data_not_available_when_custom_time_range_selected() {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: nil,
                                             timeRange: .custom(start: Date(), end: Date()),
                                             isJetpackStatsDisabled: false,
                                             updateSiteStatsData: {})

        // Then
        XCTAssertFalse(vm.isSessionsDataAvailable)
    }

    // MARK: Jetpack Stats CTA

    @MainActor
    func test_showJetpackStatsCTA_true_for_admin_when_stats_module_disabled() async {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: true,
                                             stores: stores,
                                             updateSiteStatsData: {})

        // Then
        XCTAssertTrue(vm.showJetpackStatsCTA)
    }

    @MainActor
    func test_enableJetpackStats_hides_call_to_action_after_successfully_enabling_stats() async {
        // Given
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: true,
                                             stores: stores,
                                             updateSiteStatsData: {})
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.success(()))
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
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: true,
                                             stores: stores,
                                             noticePresenter: noticePresenter,
                                             updateSiteStatsData: {})
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
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: true,
                                             stores: stores,
                                             analytics: analytics,
                                             updateSiteStatsData: {})
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.success(()))
            }
        }

        // When
        vm.trackJetpackStatsCTAShown()
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
        let vm = SessionsReportCardViewModel(siteID: sampleSiteID,
                                             currentOrderStats: nil,
                                             siteStats: .fake(),
                                             timeRange: .today,
                                             isJetpackStatsDisabled: true,
                                             stores: stores,
                                             analytics: analytics,
                                             updateSiteStatsData: {})
        stores.whenReceivingAction(ofType: JetpackSettingsAction.self) { action in
            switch action {
            case let .enableJetpackModule(_, _, completion):
                completion(.failure(NSError(domain: "Test", code: 1)))
            }
        }

        // When
        vm.trackJetpackStatsCTAShown()
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

}
