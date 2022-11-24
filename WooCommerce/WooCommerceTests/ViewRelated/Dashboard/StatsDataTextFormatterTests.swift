import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

/// `StatsDataTextFormatter` tests.
/// 
final class StatsDataTextFormatterTests: XCTestCase {

    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US
    private let currencyCode = CurrencySettings().currencyCode

    // MARK: Revenue Stats

    func test_createTotalRevenueText_does_not_return_decimal_points_for_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62))

        // When
        let totalRevenue = StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStats,
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
        let totalRevenue = StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStats,
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
        let selectedIntervalIndex = 1 // Corresponds to the second earliest interval, which is the first interval in `OrderStatsV4`.

        // When
        let totalRevenue = StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStats,
                                                                    selectedIntervalIndex: selectedIntervalIndex,
                                                                    currencyFormatter: currencyFormatter,
                                                                    currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(totalRevenue, "$25")
    }

    func test_createTotalRevenueDelta_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 10))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 15))

        // When
        let totalRevenueDelta = StatsDataTextFormatter.createTotalRevenueDelta(from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(totalRevenueDelta.string, "+50%")
        XCTAssertEqual(totalRevenueDelta.direction, .positive)
    }

    // MARK: Orders Stats

    func test_createOrderCountText_returns_expected_order_count() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let orderCount = StatsDataTextFormatter.createOrderCountText(orderStats: orderStats, selectedIntervalIndex: nil)

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
        let selectedIntervalIndex = 1 // Corresponds to the second earliest interval, which is the first interval in `OrderStatsV4`.

        // When
        let orderCount = StatsDataTextFormatter.createOrderCountText(orderStats: orderStats, selectedIntervalIndex: selectedIntervalIndex)

        // Then
        XCTAssertEqual(orderCount, "1")
    }

    func test_createOrderCountDelta_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 10))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15))

        // When
        let orderCountDelta = StatsDataTextFormatter.createOrderCountDelta(from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(orderCountDelta.string, "+50%")
        XCTAssertEqual(orderCountDelta.direction, .positive)
    }

    func test_createAverageOrderValueText_does_not_return_decimal_points_for_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62))

        // When
        let averageOrderValue = StatsDataTextFormatter.createAverageOrderValueText(orderStats: orderStats,
                                                                              currencyFormatter: currencyFormatter,
                                                                              currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(averageOrderValue, "$62")
    }

    func test_createAverageOrderValueText_returns_decimal_points_from_currency_settings_for_noninteger_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62.856))

        // When
        let averageOrderValue = StatsDataTextFormatter.createAverageOrderValueText(orderStats: orderStats,
                                                                              currencyFormatter: currencyFormatter,
                                                                              currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(averageOrderValue, "$62.86")
    }

    func test_createAverageOrderValueDelta_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 10.00))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 15.00))

        // When
        let averageOrderValueDelta = StatsDataTextFormatter.createAverageOrderValueDelta(from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(averageOrderValueDelta.string, "+50%")
        XCTAssertEqual(averageOrderValueDelta.direction, .positive)
    }

    // MARK: Views and Visitors Stats

    // This test reflects the current method for computing total visitor count.
    // It needs to be updated once this issue is fixed: https://github.com/woocommerce/woocommerce-ios/issues/8173
    func test_createVisitorCountText_returns_expected_visitor_stats() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(period: "1", visitors: 17),
                                                                         .fake().copy(period: "0", visitors: 5)])

        // When
        let visitorCount = StatsDataTextFormatter.createVisitorCountText(siteStats: siteVisitStats, selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(visitorCount, "22")
    }

    func test_createVisitorCountText_returns_expected_text_for_selected_interval() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(period: "1", visitors: 17),
                                                                         .fake().copy(period: "0", visitors: 5)])
        let selectedIntervalIndex = 1 // Corresponds to the second in intervals sorted by period, which is the first interval in `siteVisitStats`.


        // When
        let visitorCount = StatsDataTextFormatter.createVisitorCountText(siteStats: siteVisitStats, selectedIntervalIndex: selectedIntervalIndex)

        // Then
        XCTAssertEqual(visitorCount, "17")
    }

    func test_createVisitorCountDelta_returns_expected_delta() {
        // Given
        let previousSiteStats = SiteVisitStats.fake().copy(items: [.fake().copy(period: "0", visitors: 10)])
        let currentSiteStats = SiteVisitStats.fake().copy(items: [.fake().copy(period: "0", visitors: 15)])

        // When
        let visitorCountDelta = StatsDataTextFormatter.createVisitorCountDelta(from: previousSiteStats, to: currentSiteStats)

        // Then
        XCTAssertEqual(visitorCountDelta.string, "+50%")
        XCTAssertEqual(visitorCountDelta.direction, .positive)
    }

    // MARK: Conversion Stats

    func test_createConversionRateText_returns_placeholder_when_visitor_count_is_zero() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 0)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "0%")
    }

    func test_createConversionRateText_returns_one_decimal_point_when_percentage_value_has_two_decimal_points() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10000)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3557))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "35.6%") // order count: 3557, visitor count: 10000 => 0.3557 (35.57%)
    }

    func test_createConversionRateText_returns_no_decimal_point_when_percentage_value_is_integer() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: nil)

        // Then
        XCTAssertEqual(conversionRate, "30%") // order count: 3, visitor count: 10 => 0.3 (30%)
    }

    func test_createConversionRateText_returns_expected_text_for_selected_interval() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 2),
                                                  intervals: [.fake().copy(subtotals: .fake().copy(totalOrders: 1))])

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(conversionRate, "10%")
    }

    // MARK: Delta Calculations

    func test_createDeltaPercentage_returns_expected_positive_delta() {
        // Given
        let previousValue: Double = 100
        let currentValue: Double = 150

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "+50%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDeltaPercentage_returns_expected_negative_delta() {
        // Given
        let previousValue: Double = 100
        let currentValue: Double = 50

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "-50%")
        XCTAssertEqual(delta.direction, .negative)
    }

    func test_createDeltaPercentage_returns_expected_zero_delta() {
        // Given
        let previousValue: Double = 100
        let currentValue: Double = 100

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDeltaPercentage_returns_expected_zero_delta_for_zero_values() {
        // Given
        let previousValue: Double = 0
        let currentValue: Double = 0

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDeltaPercentage_returns_positive_100_percent_change_when_previous_value_is_zero() {
        // Given
        let previousValue: Double = 0
        let currentValue: Double = 10

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "+100%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDeltaPercentage_returns_negative_100_percent_change_when_previous_value_is_zero() {
        // Given
        let previousValue: Double = 0
        let currentValue: Double = -10

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "-100%")
        XCTAssertEqual(delta.direction, .negative)
    }

    func test_createDeltaPercentage_returns_negative_100_percent_change_when_current_value_is_zero() {
        // Given
        let previousValue: Double = 10
        let currentValue: Double = 0

        // When
        let delta = StatsDataTextFormatter.createDeltaPercentage(from: previousValue, to: currentValue)

        // Then
        XCTAssertEqual(delta.string, "-100%")
        XCTAssertEqual(delta.direction, .negative)
    }
}
