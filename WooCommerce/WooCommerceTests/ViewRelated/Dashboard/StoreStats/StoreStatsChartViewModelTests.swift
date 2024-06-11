import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

final class StoreStatsChartViewModelTests: XCTestCase {

    func test_hasRevenue_returns_false_if_no_interval_has_revenue() {
        // Given
        let intervals: [StoreStatsChartData] = {
            var day = 0
            var data = [StoreStatsChartData]()
            while day < 6 {
                data.append(StoreStatsChartData(date: Date().adding(days: day)!, revenue: 0))
                day += 1
            }
            return data
        }()

        // When
        let viewModel = StoreStatsChartViewModel(intervals: intervals, timeRange: .thisWeek)

        // Then
        XCTAssertFalse(viewModel.hasRevenue)
    }

    func test_hasRevenue_returns_true_if_some_intervals_have_revenues() {
        // Given
        let intervals: [StoreStatsChartData] = {
            var day = 0
            var data = [StoreStatsChartData]()
            while day < 6 {
                data.append(StoreStatsChartData(date: Date().adding(days: day)!, revenue: Double.random(in: 0...100)))
                day += 1
            }
            return data
        }()

        // When
        let viewModel = StoreStatsChartViewModel(intervals: intervals, timeRange: .thisWeek)

        // Then
        XCTAssertTrue(viewModel.hasRevenue)
    }

    func test_xAxisStride_returns_correct_values_for_different_time_ranges() {
        // Given
        let date = Date(timeIntervalSince1970: 1713571200) // April 20 2024
        let timeRangesWithXAxisStride: [StatsTimeRangeV4: Calendar.Component] = [
            .today: .hour,
            .thisWeek: .day,
            .thisMonth: .day,
            .thisYear: .month,
            .custom(from: date, to: date.adding(days: 0)!): .hour,
            .custom(from: date, to: date.adding(days: 2)!): .day,
            .custom(from: date, to: date.adding(days: 100)!): .month,
            .custom(from: date, to: date.adding(days: 1460)!): .year // 4 years
        ]

        for timeRange in timeRangesWithXAxisStride.keys {
            // When
            let viewModel = StoreStatsChartViewModel(intervals: [], timeRange: timeRange)

            // Then
            XCTAssertEqual(viewModel.xAxisStride, timeRangesWithXAxisStride[timeRange])
        }
    }

    func test_xAxisStrideCount_returns_correct_values_for_different_time_ranges() {
        // Given
        let date = Date(timeIntervalSince1970: 1713571200) // April 20 2024
        let timeRangesWithXAxisStrideCount: [StatsTimeRangeV4: Int] = [
            .today: 5,
            .thisWeek: 1,
            .thisMonth: 5,
            .thisYear: 3,
            .custom(from: date, to: date.adding(days: 0)!): 6,
        ]

        for timeRange in timeRangesWithXAxisStrideCount.keys {
            // When
            let viewModel = StoreStatsChartViewModel(intervals: [], timeRange: timeRange)

            // Then
            XCTAssertEqual(viewModel.xAxisStrideCount, timeRangesWithXAxisStrideCount[timeRange])
        }
    }

    func test_xAxisLabelFormatStyle_returns_correct_values_for_non_first_dates_in_different_time_ranges() {
        // Given
        let date = Date(timeIntervalSince1970: 1713571200) // April 20 2024
        let timeRangesWithXAxisLabelFormatStyle: [StatsTimeRangeV4: Date.FormatStyle] = [
            .today: .dateTime.hour(),
            .thisWeek: .dateTime.day(.defaultDigits),
            .thisMonth: .dateTime.day(.defaultDigits),
            .thisYear: .dateTime.month(.abbreviated),
            .custom(from: date, to: date.adding(days: 0)!): .dateTime.hour(),
            .custom(from: date, to: date.adding(days: 2)!): .dateTime.day(.defaultDigits),
            .custom(from: date, to: date.adding(days: 100)!): .dateTime.month(.abbreviated),
            .custom(from: date, to: date.adding(days: 1460)!): .dateTime.year() // 4 years
        ]

        for timeRange in timeRangesWithXAxisLabelFormatStyle.keys {
            // When
            let viewModel = StoreStatsChartViewModel(intervals: [], timeRange: timeRange)

            // Then
            XCTAssertEqual(viewModel.xAxisLabelFormatStyle(for: Date().adding(days: 1)!),
                           timeRangesWithXAxisLabelFormatStyle[timeRange])
        }
    }

    func test_xAxisLabelFormatStyle_returns_correct_values_for_first_dates_in_different_time_ranges() {
        // Given
        let currentDate = Date()
        let timeRanges: [StatsTimeRangeV4] = [
            .thisWeek,
            .thisMonth,
            .custom(from: currentDate, to: currentDate.adding(days: 2)!)
        ]
        let intervals = [StoreStatsChartData(date: currentDate, revenue: 100)]

        for timeRange in timeRanges {
            // When
            let viewModel = StoreStatsChartViewModel(intervals: intervals, timeRange: timeRange)

            // Then
            XCTAssertEqual(viewModel.xAxisLabelFormatStyle(for: currentDate),
                           .dateTime.month(.abbreviated).day(.defaultDigits))
        }
    }

    func test_yAxisStride_returns_correct_value() {
        // Given
        let currentDate = Date()
        let intervals = [
            StoreStatsChartData(date: currentDate, revenue: 100),
            StoreStatsChartData(date: currentDate.adding(days: 1)!, revenue: 110),
            StoreStatsChartData(date: currentDate.adding(days: 2)!, revenue: 0),
            StoreStatsChartData(date: currentDate.adding(days: 3)!, revenue: 0),
            StoreStatsChartData(date: currentDate.adding(days: 4)!, revenue: 130),
            StoreStatsChartData(date: currentDate.adding(days: 5)!, revenue: 0),
            StoreStatsChartData(date: currentDate.adding(days: 6)!, revenue: 200)
        ]

        // When
        let viewModel = StoreStatsChartViewModel(intervals: intervals, timeRange: .thisWeek)

        // Then
        XCTAssertEqual(viewModel.yAxisStride, 100)
    }

    func test_yAxisStride_can_handle_negative_revenue_values() {
        // Given
        let currentDate = Date()
        let intervals = [
            StoreStatsChartData(date: currentDate, revenue: 100),
            StoreStatsChartData(date: currentDate.adding(days: 1)!, revenue: -10),
            StoreStatsChartData(date: currentDate.adding(days: 2)!, revenue: 130),
        ]

        // When
        let viewModel = StoreStatsChartViewModel(intervals: intervals, timeRange: .thisWeek)

        // Then
        XCTAssertEqual(viewModel.yAxisStride, 70)
    }

    func test_yAxisLabel_is_correct_for_zero_revenue() {
        // Given
        let viewModel = StoreStatsChartViewModel(intervals: [], timeRange: .thisWeek)

        // When
        let label = viewModel.yAxisLabel(for: 0)

        // Then
        XCTAssertEqual(label, "")
    }

    func test_yAxisLabel_is_correct_for_non_zero_revenue() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .left, thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 2)
        let viewModel = StoreStatsChartViewModel(intervals: [],
                                                 timeRange: .thisWeek,
                                                 currencySettings: currencySettings,
                                                 currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))

        // When
        let label = viewModel.yAxisLabel(for: 1000)

        // Then
        XCTAssertEqual(label, "$1k")

        // When
        let anotherLabel = viewModel.yAxisLabel(for: 100)

        // Then
        XCTAssertEqual(anotherLabel, "$100")
    }
}
