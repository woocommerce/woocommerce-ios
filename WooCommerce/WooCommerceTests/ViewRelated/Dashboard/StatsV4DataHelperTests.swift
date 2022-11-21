import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

/// `StatsV4DataHelper` tests.
/// 
final class StatsV4DataHelperTests: XCTestCase {

    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US
    private let currencyCode = CurrencySettings().currencyCode

    // MARK: Revenue Stats

    func test_createTotalRevenueText_does_not_return_decimal_points_for_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62))

        // When
        let totalRevenue = StatsV4DataHelper.createTotalRevenueText(orderStatsData: (orderStats, []),
                                                                    selectedIntervalIndex: nil,
                                                                    currencyFormatter: currencyFormatter,
                                                                    currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(totalRevenue, "$62")
    }

    func test_createTotalRevenueText_returns_decimal_points_from_currency_settings_for_noninteger_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62.856))

        // When
        let totalRevenue = StatsV4DataHelper.createTotalRevenueText(orderStatsData: (orderStats, []),
                                                                    selectedIntervalIndex: nil,
                                                                    currencyFormatter: currencyFormatter,
                                                                    currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(totalRevenue, "$62.86")
    }

    func test_createTotalRevenueText_returns_expected_text_for_selected_interval() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62.7),
                                      intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                               dateEnd: "2019-07-09 01:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 25)),
                                                  .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                               dateEnd: "2019-07-09 00:59:59",
                                                               subtotals: .fake().copy(grossRevenue: 31))
                                                 ])

        // When
        let totalRevenue = StatsV4DataHelper.createTotalRevenueText(orderStatsData: (orderStats, orderStats.intervals),
                                                                    selectedIntervalIndex: 0,
                                                                    currencyFormatter: currencyFormatter,
                                                                    currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(totalRevenue, "$25")
    }

    // MARK: Orders Stats

    func test_createOrderCountText_returns_expected_order_count() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let orderCount = StatsV4DataHelper.createOrderCountText(orderStatsData: (orderStats, []), selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(orderCount, "3")
    }

    func test_createOrderCountText_returns_expected_text_for_selected_interval() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3),
                                      intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                               dateEnd: "2019-07-09 01:59:59",
                                                               subtotals: .fake().copy(totalOrders: 1, grossRevenue: 25)),
                                                  .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                               dateEnd: "2019-07-09 00:59:59",
                                                               subtotals: .fake().copy(totalOrders: 2, grossRevenue: 31))
                                                 ])

        // When
        let orderCount = StatsV4DataHelper.createOrderCountText(orderStatsData: (orderStats, orderStats.intervals), selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(orderCount, "1")
    }

    func test_createAverageOrderValueText_does_not_return_decimal_points_for_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62))

        // When
        let averageOrderValue = StatsV4DataHelper.createAverageOrderValueText(orderStatsData: (orderStats, []),
                                                                              currencyFormatter: currencyFormatter,
                                                                              currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(averageOrderValue, "$62")
    }

    func test_createAverageOrderValueText_returns_decimal_points_from_currency_settings_for_noninteger_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62.856))

        // When
        let averageOrderValue = StatsV4DataHelper.createAverageOrderValueText(orderStatsData: (orderStats, []),
                                                                              currencyFormatter: currencyFormatter,
                                                                              currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(averageOrderValue, "$62.86")
    }

    // MARK: Views and Visitors Stats

    // This test reflects the current method for computing total visitor count.
    // It needs to be updated once this issue is fixed: https://github.com/woocommerce/woocommerce-ios/issues/8173
    func test_createVisitorCountText_returns_expected_visitor_stats() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(period: "1", visitors: 17),
                                                                         .fake().copy(period: "0", visitors: 5)])

        // When
        let visitorCount = StatsV4DataHelper.createVisitorCountText(siteStats: siteVisitStats, selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(visitorCount, "22")
    }

    func test_createVisitorCountText_returns_expected_text_for_selected_interval() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(period: "1", visitors: 17),
                                                                         .fake().copy(period: "0", visitors: 5)])
        let selectedIntervalIndex = 1 // Corresponds to the second in intervals sorted by period, which is the first interval in `siteVisitStats`.


        // When
        let visitorCount = StatsV4DataHelper.createVisitorCountText(siteStats: siteVisitStats, selectedIntervalIndex: selectedIntervalIndex)

        // Then
        XCTAssertEqual(visitorCount, "17")
    }

    // MARK: Conversion Stats

    func test_createConversionRateText_returns_placeholder_when_visitor_count_is_zero() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 0)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsV4DataHelper.createConversionRateText(orderStatsData: (orderStats, []),
                                                                        siteStats: siteVisitStats,
                                                                        selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "0%")
    }

    func test_createConversionRateText_returns_one_decimal_point_when_percentage_value_has_two_decimal_points() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10000)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3557))

        // When
        let conversionRate = StatsV4DataHelper.createConversionRateText(orderStatsData: (orderStats, []),
                                                                        siteStats: siteVisitStats,
                                                                        selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "35.6%") // order count: 3557, visitor count: 10000 => 0.3557 (35.57%)
    }

    func test_createConversionRateText_returns_no_decimal_point_when_percentage_value_is_integer() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsV4DataHelper.createConversionRateText(orderStatsData: (orderStats, []),
                                                                        siteStats: siteVisitStats,
                                                                        selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "30%") // order count: 3, visitor count: 10 => 0.3 (30%)
    }

    func test_createConversionRateText_returns_expected_text_for_selected_interval() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 2),
                                                  intervals: [.fake().copy(subtotals: .fake().copy(totalOrders: 1))])

        // When
        let conversionRate = StatsV4DataHelper.createConversionRateText(orderStatsData: (orderStats, orderStats.intervals),
                                                                        siteStats: siteVisitStats,
                                                                        selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(conversionRate, "10%")
    }
}
