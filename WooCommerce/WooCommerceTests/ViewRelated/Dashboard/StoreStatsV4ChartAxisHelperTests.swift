import XCTest
@testable import WooCommerce

class StoreStatsV4ChartAxisHelperTests: XCTestCase {
    private let helper = StoreStatsV4ChartAxisHelper()

    func testDatesAcrossTwoMonths() {
        // GMT: Saturday, June 1, 2019 12:29:29 AM
        let dateInJune = Date(timeIntervalSince1970: 1559348969)
        // GMT: Monday, June 10, 2019 12:29:29 AM
        let secondDateInJune = Date(timeIntervalSince1970: 1560126569)
        // GMT: Thursday, August 1, 2019 12:29:29 AM
        let dateInAugust = Date(timeIntervalSince1970: 1564619369)
        let dates = [dateInAugust, dateInJune, secondDateInJune]
        let timezone = TimeZone(identifier: "GMT")!
        let text = helper.generateLabelText(for: dates, timeRange: .thisWeek, siteTimezone: timezone)
        let textOfDateInAugust = text[0]
        let textOfFirstDateInJune = text[1]
        let textOfSecondDateInJune = text[2]
        XCTAssertEqual(textOfDateInAugust, dayMonthFormatter(timezone: timezone).string(from: dateInAugust))
        XCTAssertEqual(textOfFirstDateInJune, dayMonthFormatter(timezone: timezone).string(from: dateInJune))
        XCTAssertEqual(textOfSecondDateInJune, dayOfMonthFormatter(timezone: timezone).string(from: secondDateInJune))
    }

    private func dayOfMonthFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d")
        formatter.timeZone = timezone
        return formatter
    }

    private func dayMonthFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        return formatter
    }
}
