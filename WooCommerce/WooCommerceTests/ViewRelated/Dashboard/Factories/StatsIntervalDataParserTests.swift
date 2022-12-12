import XCTest
import Yosemite
@testable import WooCommerce

final class StatsIntervalDataParserTests: XCTestCase {

    func test_getChartData_for_totalRevenue_returns_expected_values() {
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
        let totalRevenueData = StatsIntervalDataParser.getChartData(for: .totalRevenue, from: orderStats)

        // Then
        XCTAssertEqual(totalRevenueData, [31, 25])
    }

    func test_getChartData_for_netRevenue_returns_expected_values() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(netRevenue: 15),
                                                  intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                                           dateEnd: "2019-07-09 01:59:59",
                                                                           subtotals: .fake().copy(netRevenue: 10)),
                                                              .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                                           dateEnd: "2019-07-09 00:59:59",
                                                                           subtotals: .fake().copy(netRevenue: 5))
                                                  ])

        // When
        let netRevenueData = StatsIntervalDataParser.getChartData(for: .netRevenue, from: orderStats)

        // Then
        XCTAssertEqual(netRevenueData, [5, 10])
    }

    func test_getChartData_for_orderCount_returns_expected_values() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(totalOrders: 3),
                                                  intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                                           dateEnd: "2019-07-09 01:59:59",
                                                                           subtotals: .fake().copy(totalOrders: 1)),
                                                              .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                                           dateEnd: "2019-07-09 00:59:59",
                                                                           subtotals: .fake().copy(totalOrders: 2))
                                                  ])

        // When
        let orderCountData = StatsIntervalDataParser.getChartData(for: .orderCount, from: orderStats)

        // Then
        XCTAssertEqual(orderCountData, [2, 1])
    }

    func test_getChartData_for_averageOrderValue_returns_expected_values() {
        // Given
        let orderStats = OrderStatsV4.fake().copy(totals: .fake().copy(averageOrderValue: 25),
                                                  intervals: [.fake().copy(dateStart: "2019-07-09 01:00:00",
                                                                           dateEnd: "2019-07-09 01:59:59",
                                                                           subtotals: .fake().copy(averageOrderValue: 30)),
                                                              .fake().copy(dateStart: "2019-07-09 00:00:00",
                                                                           dateEnd: "2019-07-09 00:59:59",
                                                                           subtotals: .fake().copy(averageOrderValue: 20))
                                                  ])

        // When
        let averageOrderValueData = StatsIntervalDataParser.getChartData(for: .averageOrderValue, from: orderStats)

        // Then
        XCTAssertEqual(averageOrderValueData, [20, 30])
    }

}
