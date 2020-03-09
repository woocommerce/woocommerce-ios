import XCTest
@testable import WooCommerce

class StatsTimeRangeBarViewModelTests: XCTestCase {

    func testTodayText() {
        // GMT: Thursday, August 15, 2019 6:14:35 PM
        let startDate = Date(timeIntervalSince1970: 1565892875)
        // GMT: Friday, August 16, 2019 2:14:35 AM
        let endDate = Date(timeIntervalSince1970: 1565921675)
        let timezone = TimeZone(identifier: "GMT") ?? .current
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .today,
                                                   timezone: timezone)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func testThisWeekText() {
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisWeek,
                                                   timezone: timezone)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        let expectedText = String.localizedStringWithFormat(NSLocalizedString("%1$@-%2$@", comment: "Displays a date range for a stats interval"),
                                                            formatter.string(from: startDate),
                                                            formatter.string(from: endDate))
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func testThisMonthText() {
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisMonth,
                                                   timezone: timezone)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }

    func testThisYearText() {
        // GMT: Sunday, July 28, 2019 12:00:00 AM
        let startDate = Date(timeIntervalSince1970: 1564272000)
        // GMT: Saturday, August 3, 2019 11:59:59 PM
        let endDate = Date(timeIntervalSince1970: 1564876799)
        let timezone = TimeZone(identifier: "GMT") ?? .current
        let viewModel = StatsTimeRangeBarViewModel(startDate: startDate,
                                                   endDate: endDate,
                                                   timeRange: .thisYear,
                                                   timezone: timezone)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        formatter.timeZone = timezone
        let expectedText = formatter.string(from: startDate)
        XCTAssertEqual(viewModel.timeRangeText, expectedText)
    }
}
