import XCTest
@testable import Networking
@testable import NetworkingCore
@testable import WooCommerce

final class StoreInfoDataServiceTests: XCTestCase {

    func test_fetchTodayStats_when_wpcom_visitors_are_available_then_returns_stats_with_visitors() async throws {
        // Given
        let orderStats = makeOrderStats(totalOrders: 4, grossRevenue: 120)
        let siteSummaryStats = SiteSummaryStats(siteID: 123,
                                                date: "2026-04-28",
                                                period: .day,
                                                visitors: 10,
                                                views: 30)
        let service = StoreInfoDataService(visitorStatsSource: .wpcomSummary,
                                           fetchTodaysRevenueAndOrders: { _ in orderStats },
                                           fetchTodaysWPComVisitors: { _ in siteSummaryStats },
                                           fetchTodaysJetpackVisitors: { _ in
                                               XCTFail("Unexpected Jetpack visitor fetch")
                                               throw TestError.unexpectedFetch
                                           })

        // When
        let stats = try await service.fetchTodayStats(for: 123)

        // Then
        XCTAssertEqual(stats.revenue, 120)
        XCTAssertEqual(stats.totalOrders, 4)
        XCTAssertEqual(stats.totalVisitors, 10)
        XCTAssertEqual(stats.conversion, 0.4)
    }

    func test_fetchTodayStats_when_jetpack_visitors_are_available_then_returns_stats_with_visitors() async throws {
        // Given
        let orderStats = makeOrderStats(totalOrders: 5, grossRevenue: 200)
        let siteVisitStats = SiteVisitStats(siteID: 123,
                                            date: "2026-04-28",
                                            granularity: .day,
                                            items: [
                                                .init(period: "2026-04-28", visitors: 8, views: 21),
                                            ])
        let service = StoreInfoDataService(visitorStatsSource: .jetpackSiteVisits,
                                           fetchTodaysRevenueAndOrders: { _ in orderStats },
                                           fetchTodaysWPComVisitors: { _ in
                                               XCTFail("Unexpected WP.com visitor fetch")
                                               throw TestError.unexpectedFetch
                                           },
                                           fetchTodaysJetpackVisitors: { _ in siteVisitStats })

        // When
        let stats = try await service.fetchTodayStats(for: 123)

        // Then
        XCTAssertEqual(stats.revenue, 200)
        XCTAssertEqual(stats.totalOrders, 5)
        XCTAssertEqual(stats.totalVisitors, 8)
        XCTAssertEqual(stats.conversion, 0.625)
    }

    func test_fetchTodayStats_when_jetpack_visitor_fetch_fails_then_falls_back_to_revenue_and_orders_only() async throws {
        // Given
        let orderStats = makeOrderStats(totalOrders: 2, grossRevenue: 75)
        let service = StoreInfoDataService(visitorStatsSource: .jetpackSiteVisits,
                                           fetchTodaysRevenueAndOrders: { _ in orderStats },
                                           fetchTodaysWPComVisitors: { _ in
                                               XCTFail("Unexpected WP.com visitor fetch")
                                               throw TestError.unexpectedFetch
                                           },
                                           fetchTodaysJetpackVisitors: { _ in
                                               throw TestError.expectedFailure
                                           })

        // When
        let stats = try await service.fetchTodayStats(for: 123)

        // Then
        XCTAssertEqual(stats.revenue, 75)
        XCTAssertEqual(stats.totalOrders, 2)
        XCTAssertNil(stats.totalVisitors)
        XCTAssertNil(stats.conversion)
    }

    func test_fetchTodayStats_when_visitor_stats_are_unavailable_then_skips_visitor_fetch() async throws {
        // Given
        let orderStats = makeOrderStats(totalOrders: 3, grossRevenue: 90)
        let service = StoreInfoDataService(visitorStatsSource: .unavailable,
                                           fetchTodaysRevenueAndOrders: { _ in orderStats },
                                           fetchTodaysWPComVisitors: { _ in
                                               XCTFail("Unexpected WP.com visitor fetch")
                                               throw TestError.unexpectedFetch
                                           },
                                           fetchTodaysJetpackVisitors: { _ in
                                               XCTFail("Unexpected Jetpack visitor fetch")
                                               throw TestError.unexpectedFetch
                                           })

        // When
        let stats = try await service.fetchTodayStats(for: 123)

        // Then
        XCTAssertEqual(stats.revenue, 90)
        XCTAssertEqual(stats.totalOrders, 3)
        XCTAssertNil(stats.totalVisitors)
        XCTAssertNil(stats.conversion)
    }
}

private extension StoreInfoDataServiceTests {

    func makeOrderStats(totalOrders: Int, grossRevenue: Decimal) -> OrderStatsV4 {
        let totals = OrderStatsV4Totals(totalOrders: totalOrders,
                                        totalItemsSold: totalOrders,
                                        grossRevenue: grossRevenue,
                                        netRevenue: grossRevenue,
                                        averageOrderValue: grossRevenue)
        let interval = OrderStatsV4Interval(interval: "2026-04-28",
                                            dateStart: "2026-04-28T00:00:00",
                                            dateEnd: "2026-04-28T23:59:59",
                                            subtotals: totals)
        return OrderStatsV4(siteID: 123,
                            granularity: .hourly,
                            totals: totals,
                            intervals: [interval])
    }

    enum TestError: Error {
        case expectedFailure
        case unexpectedFetch
    }
}
