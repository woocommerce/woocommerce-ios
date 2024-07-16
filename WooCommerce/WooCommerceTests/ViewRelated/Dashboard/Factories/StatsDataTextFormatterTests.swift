import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

/// `StatsDataTextFormatter` tests.
///
final class StatsDataTextFormatterTests: XCTestCase {

    private let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings()) // Default is US
    private let currencyCode = CurrencySettings().currencyCode
    private let fractionDigits = CurrencySettings().fractionDigits

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

    func test_createTotalRevenueText_does_not_return_decimal_points_for_rounded_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62.0000000000002))

        // When
        let totalRevenue = StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStats,
                                                                    selectedIntervalIndex: nil,
                                                                    currencyFormatter: currencyFormatter,
                                                                    currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(totalRevenue, "$62")
    }

    func test_createTotalRevenueText_returns_expected_number_of_fractional_digits() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 62.0023))
        let customCurrencySettings = CurrencySettings()
        customCurrencySettings.fractionDigits = 3
        let currencyFormatter = CurrencyFormatter(currencySettings: customCurrencySettings)

        // When
        let totalRevenue = StatsDataTextFormatter.createTotalRevenueText(orderStats: orderStats,
                                                                         selectedIntervalIndex: nil,
                                                                         currencyFormatter: currencyFormatter,
                                                                         currencyCode: currencyCode.rawValue,
                                                                         numberOfFractionDigits: 3)

        // Then
        XCTAssertEqual(totalRevenue, "$62.002")
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

    func test_createDelta_for_grossRevenue_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 10))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(grossRevenue: 15))

        // When
        let totalRevenueDelta = StatsDataTextFormatter.createDelta(for: .grossRevenue, from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(totalRevenueDelta.string, "+50%")
        XCTAssertEqual(totalRevenueDelta.direction, .positive)
    }

    func test_createNetRevenueText_does_not_return_decimal_points_for_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 62))

        // When
        let netRevenue = StatsDataTextFormatter.createNetRevenueText(orderStats: orderStats,
                                                                     currencyFormatter: currencyFormatter,
                                                                     currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(netRevenue, "$62")
    }

    func test_createNetRevenueText_does_not_return_decimal_points_for_rounded_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 62.0000000000002))

        // When
        let netRevenue = StatsDataTextFormatter.createNetRevenueText(orderStats: orderStats,
                                                                     currencyFormatter: currencyFormatter,
                                                                     currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(netRevenue, "$62")
    }

    func test_createNetRevenueText_returns_expected_number_of_fractional_digits() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 62.0023))
        let customCurrencySettings = CurrencySettings()
        customCurrencySettings.fractionDigits = 3
        let currencyFormatter = CurrencyFormatter(currencySettings: customCurrencySettings)

        // When
        let netRevenue = StatsDataTextFormatter.createNetRevenueText(orderStats: orderStats,
                                                                     currencyFormatter: currencyFormatter,
                                                                     currencyCode: currencyCode.rawValue,
                                                                     numberOfFractionDigits: 3)

        // Then
        XCTAssertEqual(netRevenue, "$62.002")
    }

    func test_createNetRevenueText_returns_decimal_points_from_currency_settings_for_noninteger_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 62.856))

        // When
        let netRevenue = StatsDataTextFormatter.createNetRevenueText(orderStats: orderStats,
                                                                     currencyFormatter: currencyFormatter,
                                                                     currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(netRevenue, "$62.86")
    }

    func test_createDelta_for_netRevenue_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 10))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 15))

        // When
        let netRevenueDelta = StatsDataTextFormatter.createDelta(for: .netRevenue, from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(netRevenueDelta.string, "+50%")
        XCTAssertEqual(netRevenueDelta.direction, .positive)
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

    func test_createDelta_for_totalOrders_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 10))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 15))

        // When
        let orderCountDelta = StatsDataTextFormatter.createDelta(for: .totalOrders, from: previousOrderStats, to: currentOrderStats)

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

    func test_createAverageOrderValueText_does_not_return_decimal_points_for_rounded_integer_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62.0000000000002))

        // When
        let averageOrderValue = StatsDataTextFormatter.createAverageOrderValueText(orderStats: orderStats,
                                                                              currencyFormatter: currencyFormatter,
                                                                              currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(averageOrderValue, "$62")
    }

    func test_createAverageOrderValueText_returns_expected_number_of_fractional_digits() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 62.0023))
        let customCurrencySettings = CurrencySettings()
        customCurrencySettings.fractionDigits = 3
        let currencyFormatter = CurrencyFormatter(currencySettings: customCurrencySettings)

        // When
        let averageOrderValue = StatsDataTextFormatter.createAverageOrderValueText(orderStats: orderStats,
                                                                                   currencyFormatter: currencyFormatter,
                                                                                   currencyCode: currencyCode.rawValue,
                                                                                   numberOfFractionDigits: 3)

        // Then
        XCTAssertEqual(averageOrderValue, "$62.002")
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

    func test_createDelta_for_averageOrderValue_returns_expected_delta() {
        // Given
        let previousOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 10.00))
        let currentOrderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 15.00))

        // When
        let averageOrderValueDelta = StatsDataTextFormatter.createDelta(for: .averageOrderValue, from: previousOrderStats, to: currentOrderStats)

        // Then
        XCTAssertEqual(averageOrderValueDelta.string, "+50%")
        XCTAssertEqual(averageOrderValueDelta.direction, .positive)
    }

    // MARK: Views and Visitors Stats

    func test_createVisitorCountText_for_SiteSummaryStats_returns_expected_visitor_stats() {
        // Given
        let siteSummaryStats = Yosemite.SiteSummaryStats.fake().copy(visitors: 20)

        // When
        let visitorCount = StatsDataTextFormatter.createVisitorCountText(siteStats: siteSummaryStats)

        // Then
        XCTAssertEqual(visitorCount, "20")
    }

    func test_createVisitorCountText_for_SiteVisitStats_returns_expected_text_for_selected_interval() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(period: "1", visitors: 17),
                                                                         .fake().copy(period: "0", visitors: 5)])
        let selectedIntervalIndex = 1 // Corresponds to the second in intervals sorted by period, which is the first interval in `siteVisitStats`.


        // When
        let visitorCount = StatsDataTextFormatter.createVisitorCountText(siteStats: siteVisitStats, selectedIntervalIndex: selectedIntervalIndex)

        // Then
        XCTAssertEqual(visitorCount, "17")
    }

    func test_createViewsCountText_returns_expected_views_stats() {
        // Given
        let siteVisitStats = SiteSummaryStats.fake().copy(views: 250)

        // When
        let viewsCount = StatsDataTextFormatter.createViewsCountText(siteStats: siteVisitStats)

        // Then
        XCTAssertEqual(viewsCount, "250")
    }

    // MARK: Conversion Stats

    func test_createConversionRateText_for_SiteVisitStats_returns_placeholder_when_visitor_count_is_zero() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 0)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(conversionRate, "0%")
    }

    func test_createConversionRateText_for_SiteVisitStats_returns_one_decimal_point_when_percentage_value_has_two_decimal_points() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10000)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3557))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(conversionRate, "35.6%") // order count: 3557, visitor count: 10000 => 0.3557 (35.57%)
    }

    func test_createConversionRateText_for_SiteVisitStats_returns_no_decimal_point_when_percentage_value_is_integer() {
        // Given
        let siteVisitStats = Yosemite.SiteVisitStats.fake().copy(items: [.fake().copy(visitors: 10)])
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteVisitStats, selectedIntervalIndex: 0)

        // Then
        XCTAssertEqual(conversionRate, "30%") // order count: 3, visitor count: 10 => 0.3 (30%)
    }

    func test_createConversionRateText_for_SiteSummaryStats_returns_placeholder_when_visitor_count_is_zero() {
        // Given
        let siteSummaryStats = SiteSummaryStats.fake().copy(visitors: 0)
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteSummaryStats)

        // Then
        XCTAssertEqual(conversionRate, "0%")
    }

    func test_createConversionRateText_for_SiteSummaryStats_returns_one_decimal_point_when_percentage_value_has_two_decimal_points() {
        // Given
        let siteSummaryStats = SiteSummaryStats.fake().copy(visitors: 10000)
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3557))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteSummaryStats)

        // Then
        XCTAssertEqual(conversionRate, "35.6%") // order count: 3557, visitor count: 10000 => 0.3557 (35.57%)
    }

    func test_createConversionRateText_for_SiteSummaryStats_returns_no_decimal_point_when_percentage_value_is_integer() {
        // Given
        let siteSummaryStats = SiteSummaryStats.fake().copy(visitors: 10)
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3))

        // When
        let conversionRate = StatsDataTextFormatter.createConversionRateText(orderStats: orderStats, siteStats: siteSummaryStats)

        // Then
        XCTAssertEqual(conversionRate, "30%") // order count: 3, visitor count: 10 => 0.3 (30%)
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

    func test_createItemsSoldText_returns_placeholder_on_nil_stats() {
        let text = StatsDataTextFormatter.createItemsSoldText(orderStats: nil)
        XCTAssertEqual(text, "-")
    }

    func test_createItemsSoldText_returns_formatted_value() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 67890))

        // When
        let text = StatsDataTextFormatter.createItemsSoldText(orderStats: orderStats)

        // Then
        XCTAssertEqual(text, "67.9k")
    }

    func test_createDelta_for_totalItemsSold_returns_zero_on_nil_stats() {
        let stats: OrderStatsV4? = nil
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: stats, to: stats)
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDelta_for_totalItemsSold_returns_correct_positive_value() {
        // Given
        let previousStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 100))
        let currentStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 133))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "+33%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDelta_for_totalItemsSold_returns_correct_negative_value() {
        // Given
        let previousStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 100))
        let currentStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalItemsSold: 77))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "-23%")
        XCTAssertEqual(delta.direction, .negative)
    }

    // MARK: Bundles Stats

    func test_createBundlesSoldText_returns_placeholder_on_nil_stats() {
        let text = StatsDataTextFormatter.createBundlesSoldText(bundleStats: nil)
        XCTAssertEqual(text, "-")
    }

    func test_createBundlesSoldText_returns_formatted_value() {
        // Given
        let bundleStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 67890))

        // When
        let text = StatsDataTextFormatter.createBundlesSoldText(bundleStats: bundleStats)

        // Then
        XCTAssertEqual(text, "67.9k")
    }

    func test_createDelta_for_bundlesSold_returns_zero_on_nil_stats() {
        let stats: ProductBundleStats? = nil
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: stats, to: stats)
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDelta_for_bundlesSold_returns_correct_positive_value() {
        // Given
        let previousStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 100))
        let currentStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 133))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "+33%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDelta_for_bundlesSold_returns_correct_negative_value() {
        // Given
        let previousStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 100))
        let currentStats = ProductBundleStats.fake().copy(totals: .fake().copy(totalItemsSold: 77))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .totalItemsSold, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "-23%")
        XCTAssertEqual(delta.direction, .negative)
    }

    // MARK: Gift Card Stats

    func test_createGiftCardsUsedText_returns_placeholder_on_nil_stats() {
        let text = StatsDataTextFormatter.createGiftCardsUsedText(giftCardStats: nil)
        XCTAssertEqual(text, "-")
    }

    func test_createGiftCardsUsedText_returns_formatted_value() {
        // Given
        let giftCardStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 67890))

        // When
        let text = StatsDataTextFormatter.createGiftCardsUsedText(giftCardStats: giftCardStats)

        // Then
        XCTAssertEqual(text, "67.9k")
    }

    func test_createDelta_for_giftCardsCount_returns_zero_on_nil_stats() {
        let stats: GiftCardStats? = nil
        let delta = StatsDataTextFormatter.createDelta(for: .giftCardsCount, from: stats, to: stats)
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDelta_for_giftCardsCount_returns_correct_positive_value() {
        // Given
        let previousStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 100))
        let currentStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 133))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .giftCardsCount, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "+33%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDelta_for_giftCardsCount_returns_correct_negative_value() {
        // Given
        let previousStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 100))
        let currentStats = GiftCardStats.fake().copy(totals: .fake().copy(giftCardsCount: 77))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .giftCardsCount, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "-23%")
        XCTAssertEqual(delta.direction, .negative)
    }

    func test_createGiftCardsNetAmountText_returns_placeholder_on_nil_stats() {
        let text = StatsDataTextFormatter.createGiftCardsNetAmountText(giftCardStats: nil)
        XCTAssertEqual(text, "-")
    }

    func test_createGiftCardsNetAmountText_returns_formatted_value() {
        // Given
        let giftCardStats = GiftCardStats.fake().copy(totals: .fake().copy(netAmount: 62.856))

        // When
        let text = StatsDataTextFormatter.createGiftCardsNetAmountText(giftCardStats: giftCardStats,
                                                                       currencyFormatter: currencyFormatter,
                                                                       currencyCode: currencyCode.rawValue)

        // Then
        XCTAssertEqual(text, "$62.86")
    }

    func test_createDelta_for_GiftCardsStats_netAmount_returns_zero_on_nil_stats() {
        let stats: GiftCardStats? = nil
        let delta = StatsDataTextFormatter.createDelta(for: .netAmount, from: stats, to: stats)
        XCTAssertEqual(delta.string, "+0%")
        XCTAssertEqual(delta.direction, .zero)
    }

    func test_createDelta_for_GiftCardsStats_netAmount_returns_correct_positive_value() {
        // Given
        let previousStats = GiftCardStats.fake().copy(totals: .fake().copy(netAmount: 100))
        let currentStats = GiftCardStats.fake().copy(totals: .fake().copy(netAmount: 133))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .netAmount, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "+33%")
        XCTAssertEqual(delta.direction, .positive)
    }

    func test_createDelta_for_GiftCardsStats_netAmount_returns_correct_negative_value() {
        // Given
        let previousStats = GiftCardStats.fake().copy(totals: .fake().copy(netAmount: 100))
        let currentStats = GiftCardStats.fake().copy(totals: .fake().copy(netAmount: 77))

        // When
        let delta = StatsDataTextFormatter.createDelta(for: .netAmount, from: previousStats, to: currentStats)

        // Then
        XCTAssertEqual(delta.string, "-23%")
        XCTAssertEqual(delta.direction, .negative)
    }

    // MARK: formatAmount helper

    func test_formatAmount_does_not_return_decimal_points_for_integer_value() {
        // Given
        let amount: Decimal = 62

        // When
        let formattedAmount = StatsDataTextFormatter.formatAmount(amount,
                                                                  currencyFormatter: currencyFormatter,
                                                                  currencyCode: currencyCode.rawValue,
                                                                  numberOfFractionDigits: fractionDigits)

        // Then
        XCTAssertEqual(formattedAmount, "$62")
    }

    func test_formatAmount_does_not_return_decimal_points_for_rounded_integer_value() {
        // Given
        let amount: Decimal = 62.0000000000002

        // When
        let formattedAmount = StatsDataTextFormatter.formatAmount(amount,
                                                                  currencyFormatter: currencyFormatter,
                                                                  currencyCode: currencyCode.rawValue,
                                                                  numberOfFractionDigits: fractionDigits)

        // Then
        XCTAssertEqual(formattedAmount, "$62")
    }

    func test_formatAmount_returns_expected_number_of_fractional_digits() {
        // Given
        let amount: Decimal = 62.0023
        let customCurrencySettings = CurrencySettings()
        customCurrencySettings.fractionDigits = 3
        let currencyFormatter = CurrencyFormatter(currencySettings: customCurrencySettings)

        // When
        let formattedAmount = StatsDataTextFormatter.formatAmount(amount,
                                                                  currencyFormatter: currencyFormatter,
                                                                  currencyCode: currencyCode.rawValue,
                                                                  numberOfFractionDigits: customCurrencySettings.fractionDigits)

        // Then
        XCTAssertEqual(formattedAmount, "$62.002")
    }

    func test_formatAmount_returns_decimal_points_from_currency_settings_for_noninteger_value() {
        // Given
        let amount: Decimal = 62.856

        // When
        let formattedAmount = StatsDataTextFormatter.formatAmount(amount,
                                                                  currencyFormatter: currencyFormatter,
                                                                  currencyCode: currencyCode.rawValue,
                                                                  numberOfFractionDigits: fractionDigits)

        // Then
        XCTAssertEqual(formattedAmount, "$62.86")
    }

    // MARK: Google Campaign Stats

    func test_createGoogleCampaignsStatText_returns_placeholder_on_nil_stats() {
        // Given
        for stat in GoogleAdsCampaignStatsTotals.TotalData.allCases {
            // When
            let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: stat, from: nil)

            // Then
            XCTAssertEqual(text, "-", "Expected \"-\" placeholder for \(stat) text but actual text was \"\(text)\" instead")
        }
    }

    func test_createGoogleCampaignsStatText_returns_expected_sales_text() {
        // Given
        let amount: Decimal = 1232

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .sales,
                                                                        from: .fake().copy(totals: .fake().copy(sales: amount)),
                                                                        currencyFormatter: currencyFormatter,
                                                                        currencyCode: currencyCode.rawValue,
                                                                        numberOfFractionDigits: fractionDigits)

        // Then
        assertEqual("$1,232", text)
    }

    func test_createGoogleCampaignsStatText_returns_expected_spend_text() {
        // Given
        let amount: Decimal = 1232

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .spend,
                                                                        from: .fake().copy(totals: .fake().copy(spend: amount)),
                                                                        currencyFormatter: currencyFormatter,
                                                                        currencyCode: currencyCode.rawValue,
                                                                        numberOfFractionDigits: fractionDigits)

        // Then
        assertEqual("$1,232", text)
    }

    func test_createGoogleCampaignsStatText_returns_expected_clicks_text() {
        // Given
        let amount = 1232

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .clicks,
                                                                        from: .fake().copy(totals: .fake().copy(clicks: amount)))

        // Then
        assertEqual("1,232", text)
    }

    func test_createGoogleCampaignsStatText_returns_expected_impressions_text() {
        // Given
        let amount = 1232

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .impressions,
                                                                        from: .fake().copy(totals: .fake().copy(impressions: amount)))

        // Then
        assertEqual("1,232", text)
    }

    func test_createGoogleCampaignsStatText_returns_expected_conversions_text() {
        // Given
        let amount: Decimal = 1232

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsStatText(for: .conversions,
                                                                        from: .fake().copy(totals: .fake().copy(conversions: amount)))

        // Then
        assertEqual("1,232", text)
    }

    func test_createGoogleCampaignsSubtotalText_returns_expected_sales_text() {
        // Given
        let campaign = GoogleAdsCampaignStatsItem.fake().copy(subtotals: .fake().copy(sales: 1232))

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .sales,
                                                                            from: campaign,
                                                                            currencyFormatter: currencyFormatter,
                                                                            currencyCode: currencyCode.rawValue,
                                                                            numberOfFractionDigits: fractionDigits)

        // Then
        assertEqual("$1,232", text)
    }

    func test_createGoogleCampaignsSubtotalText_returns_expected_spend_text() {
        // Given
        let campaign = GoogleAdsCampaignStatsItem.fake().copy(subtotals: .fake().copy(spend: 1232))

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .spend,
                                                                            from: campaign,
                                                                            currencyFormatter: currencyFormatter,
                                                                            currencyCode: currencyCode.rawValue,
                                                                            numberOfFractionDigits: fractionDigits)

        // Then
        assertEqual("$1,232", text)
    }

    func test_createGoogleCampaignsSubtotalText_returns_expected_clicks_text() {
        // Given
        let campaign = GoogleAdsCampaignStatsItem.fake().copy(subtotals: .fake().copy(clicks: 1232))

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .clicks,
                                                                            from: campaign)

        // Then
        assertEqual("1,232", text)
    }

    func test_createGoogleCampaignsSubtotalText_returns_expected_impressions_text() {
        // Given
        let campaign = GoogleAdsCampaignStatsItem.fake().copy(subtotals: .fake().copy(impressions: 1232))

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .impressions,
                                                                            from: campaign)

        // Then
        assertEqual("1,232", text)
    }

    func test_createGoogleCampaignsSubtotalText_returns_expected_conversions_text() {
        // Given
        let campaign = GoogleAdsCampaignStatsItem.fake().copy(subtotals: .fake().copy(conversions: 1232))

        // When
        let text = StatsDataTextFormatter.createGoogleCampaignsSubtotalText(for: .conversions,
                                                                            from: campaign)

        // Then
        assertEqual("1,232", text)
    }
}
