import XCTest
import WooFoundation
import Yosemite
@testable import WooCommerce

final class OrdersReportCardViewModelTests: XCTestCase {

    private var eventEmitter: StoreStatsUsageTracksEventEmitter!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: Analytics!

    private let sampleAdminURL = "https://example.com/wp-admin/"

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        eventEmitter = StoreStatsUsageTracksEventEmitter(analytics: analytics)
        ServiceLocator.setCurrencySettings(CurrencySettings()) // Default is US
    }

    func test_it_inits_with_expected_values() {
        // Given
        let vm = OrdersReportCardViewModel(
            currentPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 60, averageOrderValue: 45),
                                                        intervals: [.fake().copy(dateStart: "2024-01-01 00:00:00",
                                                                                 subtotals: .fake().copy(totalOrders: 45, averageOrderValue: 40)),
                                                                    .fake().copy(dateStart: "2024-01-02 00:00:00",
                                                                                 subtotals: .fake().copy(totalOrders: 15, averageOrderValue: 5))]),
            previousPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 30, averageOrderValue: 30)),
            timeRange: .today,
            usageTracksEventEmitter: eventEmitter,
            storeAdminURL: sampleAdminURL
        )

        // Then
        assertEqual("60", vm.leadingValue)
        assertEqual(DeltaPercentage(string: "+100%", direction: .positive), vm.leadingDelta)
        assertEqual([45, 15], vm.leadingChartData)
        assertEqual("$45", vm.trailingValue)
        assertEqual(DeltaPercentage(string: "+50%", direction: .positive), vm.trailingDelta)
        assertEqual([40, 5], vm.trailingChartData)
        XCTAssertFalse(vm.isRedacted)
        XCTAssertFalse(vm.showSyncError)
        XCTAssertNotNil(vm.reportViewModel)
    }

    func test_it_contains_expected_reportURL_elements() throws {
        // When
        let vm = OrdersReportCardViewModel(currentPeriodStats: nil,
                                           previousPeriodStats: nil,
                                           timeRange: .monthToDate,
                                           usageTracksEventEmitter: eventEmitter,
                                           storeAdminURL: sampleAdminURL)
        let revenueCardReportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let revenueCardURLQueryItems = try XCTUnwrap(URLComponents(url: revenueCardReportURL, resolvingAgainstBaseURL: false)?.queryItems)

        // Then
        XCTAssertTrue(revenueCardReportURL.relativeString.contains(sampleAdminURL))
        XCTAssertTrue(revenueCardURLQueryItems.contains(URLQueryItem(name: "path", value: "/analytics/orders")))
        XCTAssertTrue(revenueCardURLQueryItems.contains(URLQueryItem(name: "period", value: "month")))
    }

    func test_it_shows_sync_error_when_current_stats_are_nil() {
        // Given
        let vm = OrdersReportCardViewModel(currentPeriodStats: nil, previousPeriodStats: .fake(), timeRange: .monthToDate, usageTracksEventEmitter: eventEmitter)

        // Then
        XCTAssertTrue(vm.showSyncError)
    }

    func test_it_shows_sync_error_when_previous_stats_are_nil() {
        // Given
        let vm = OrdersReportCardViewModel(currentPeriodStats: .fake(), previousPeriodStats: nil, timeRange: .monthToDate, usageTracksEventEmitter: eventEmitter)

        // Then
        XCTAssertTrue(vm.showSyncError)
    }

    func test_redact_updates_properties_as_expected() {
        // Given
        let vm = OrdersReportCardViewModel(currentPeriodStats: nil,
                                           previousPeriodStats: nil,
                                           timeRange: .monthToDate,
                                           usageTracksEventEmitter: eventEmitter,
                                           storeAdminURL: sampleAdminURL)

        // When
        vm.redact()

        // Then

        assertEqual("$1000", vm.leadingValue)
        assertEqual(DeltaPercentage(string: "0%", direction: .zero), vm.leadingDelta)
        assertEqual([], vm.leadingChartData)
        assertEqual("$1000", vm.trailingValue)
        assertEqual(DeltaPercentage(string: "0%", direction: .zero), vm.trailingDelta)
        assertEqual([], vm.trailingChartData)
        XCTAssertTrue(vm.isRedacted)
        XCTAssertFalse(vm.showSyncError)
        XCTAssertNotNil(vm.reportViewModel)
    }

    func test_properties_updated_as_expected_after_stats_update() {
        // Given
        let vm = OrdersReportCardViewModel(currentPeriodStats: nil,
                                           previousPeriodStats: nil,
                                           timeRange: .monthToDate,
                                           usageTracksEventEmitter: eventEmitter,
                                           storeAdminURL: sampleAdminURL)

        // When
        vm.update(currentPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 60)),
                  previousPeriodStats: OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 30)))

        // Then
        assertEqual("60", vm.leadingValue)
        assertEqual(DeltaPercentage(string: "+100%", direction: .positive), vm.leadingDelta)
        XCTAssertFalse(vm.isRedacted)
    }

    func test_properties_updated_as_expected_after_timeRange_update() throws {
        // Given
        let vm = OrdersReportCardViewModel(currentPeriodStats: nil,
                                           previousPeriodStats: nil,
                                           timeRange: .monthToDate,
                                           usageTracksEventEmitter: eventEmitter,
                                           storeAdminURL: sampleAdminURL)

        // When
        vm.update(timeRange: .today)

        // Then
        let reportURL = try XCTUnwrap(vm.reportViewModel?.initialURL)
        let queryItems = try XCTUnwrap(URLComponents(url: reportURL, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "period", value: "today")))
    }

}