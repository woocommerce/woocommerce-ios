import XCTest
@testable import WooCommerce
import enum Yosemite.StatsTimeRangeV4
import enum Yosemite.StatsGranularityV4

final class StatsTimeRangeBarViewModelTests: XCTestCase {
    func test_today_text() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let startDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, August 16, 2019 2:14:35 AM
        let endDate = Date(timeIntervalSince1970: 1565921675)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .today,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_today_text_with_selected_date() {
        // Given
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let startDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, August 16, 2019 2:14:35 AM
        let endDate = Date(timeIntervalSince1970: 1565921675)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .today,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d, h:mm a")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "Thursday, Aug 15, 6:14 PM" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisWeek_text() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisWeek,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        // "Jul 28 – Aug 3" in en-US locale.
        let expectedText = String.localizedStringWithFormat(NSLocalizedString("%1$@ – %2$@", comment: "Displays a date range for a stats interval"),
                                                            formatter.string(from: startDate),
                                                            formatter.string(from: endDate))
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisWeek_text_with_selected_date() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisWeek,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "Jul 28" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisMonth_text() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisMonth,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "July 2019" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisMonth_text_with_selected_date() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisMonth,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "Jul 28" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisYear_text() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisYear,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_thisYear_text_with_selected_date() {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: startDate,
                                                   timeRange: .thisYear,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate) // "July 2019" in en-US locale.
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_custom_range_text_displays_only_start_date_for_1_day_range() throws {
        // Given
        // GMT: March 4 2024 00:00:00
        let startDate = Date(timeIntervalSince1970: 1709510400)
        // GMT: March 4 2024 23:59:59
        let endDate = Date(timeIntervalSince1970: 1709596799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        let timeRange = StatsTimeRangeV4.custom(from: startDate, to: endDate)

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: timeRange,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = timezone
        // "March 4 2024" in en-US locale.
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_custom_range_text_displays_exact_date_from_custom_range_for_range_longer_than_1_day() throws {
        // Given
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        let actualStartDate = try XCTUnwrap(startDate.adding(days: -3))
        let actualEndDate = try XCTUnwrap(endDate.adding(days: 3))
        let timeRange = StatsTimeRangeV4.custom(from: actualStartDate, to: actualEndDate)

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: timeRange,
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = timezone
        // "July 25, 2019 – August 6, 2019" in en-US locale.
        let expectedText = String(format: "%1$@ – %2$@",
                                  formatter.string(from: actualStartDate),
                                  formatter.string(from: actualEndDate))
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func test_custom_range_with_selected_date_for_hourly_granularity() {
        // Given
        // GMT: March 4 2024 00:00:00
        let startDate = Date(timeIntervalSince1970: 1709510400)
        // GMT: March 4 2024 23:59:59
        let endDate = Date(timeIntervalSince1970: 1709596799)
        // GMT: March 4 2024 12:00:00
        let selectedDate = Date(timeIntervalSince1970: 1709553600)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: selectedDate,
                                                   timeRange: .custom(from: startDate, to: endDate),
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter.Charts.chartSelectedDateHourFormatter
        formatter.timeZone = timezone
        // "Monday, March 4 12:00 PM"
        let expectedDate = formatter.string(from: selectedDate)
        XCTAssertNotNil(viewModel.selectedDateText)
        XCTAssertEqual(viewModel.selectedDateText, expectedDate)
    }

    func test_custom_range_with_selected_date_for_daily_granularity() {
        // Given
        // GMT: February 28 2024 00:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1709078400)
        // GMT: March 5 2024 00:00:00 AM
        let endDate = Date(timeIntervalSince1970: 1709596800)
        // GMT: March 4 2024 12:00:00 PM
        let selectedDate = Date(timeIntervalSince1970: 1709553600)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: selectedDate,
                                                   timeRange: .custom(from: startDate, to: endDate),
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter.Charts.chartAxisDayFormatter
        formatter.timeZone = timezone
        // "Mar 4"
        let expectedDate = formatter.string(from: selectedDate)
        XCTAssertNotNil(viewModel.selectedDateText)
        XCTAssertEqual(viewModel.selectedDateText, expectedDate)    }

    func test_custom_range_with_selected_date_for_weekly_granularity() {
        // Given
        // GMT: December 28 2023 00:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1703721600)
        // GMT: March 5 2024 00:00:00 AM
        let endDate = Date(timeIntervalSince1970: 1709596800)
        // GMT: March 4 2024 12:00:00 PM
        let selectedDate = Date(timeIntervalSince1970: 1709553600)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: selectedDate,
                                                   timeRange: .custom(from: startDate, to: endDate),
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter.Charts.chartAxisDayFormatter
        formatter.timeZone = timezone
        // "Mar 4"
        let expectedDate = formatter.string(from: selectedDate)
        XCTAssertNotNil(viewModel.selectedDateText)
        XCTAssertEqual(viewModel.selectedDateText, expectedDate)
    }

    func test_custom_range_with_selected_date_for_monthly_granularity() {
        // Given
        // GMT: May 28 2023 00:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1685232000)
        // GMT: March 5 2024 00:00:00 AM
        let endDate = Date(timeIntervalSince1970: 1709596800)
        // GMT: March 4 2024 12:00:00 PM
        let selectedDate = Date(timeIntervalSince1970: 1709553600)
        let timezone = TimeZone(identifier: "GMT") ?? .current

        // When
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   selectedDate: selectedDate,
                                                   timeRange: .custom(from: startDate, to: endDate),
                                                   timezone: timezone)

        // Then
        let formatter = DateFormatter.Charts.chartAxisFullMonthFormatter
        formatter.timeZone = timezone
        // "March 2024"
        let expectedDate = formatter.string(from: selectedDate)
        XCTAssertNotNil(viewModel.selectedDateText)
        XCTAssertEqual(viewModel.selectedDateText, expectedDate)
    }
}
