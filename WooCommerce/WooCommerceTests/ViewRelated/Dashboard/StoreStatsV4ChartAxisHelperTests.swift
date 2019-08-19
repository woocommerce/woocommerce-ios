import XCTest
@testable import WooCommerce

class StoreStatsV4ChartAxisHelperTests: XCTestCase {
    private let helper = StoreStatsV4ChartAxisHelper()
    private lazy var dayOfMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d")
        return formatter
    }()

    private lazy var dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    func testDatesAcrossTwoMonths() {
        // GMT: Saturday, June 1, 2019 12:29:29 AM
        let dateInJune = Date(timeIntervalSince1970: 1559348969)
        // GMT: Monday, June 10, 2019 12:29:29 AM
        let secondDateInJune = Date(timeIntervalSince1970: 1560126569)
        // GMT: Thursday, August 1, 2019 12:29:29 AM
        let dateInAugust = Date(timeIntervalSince1970: 1561940969)
        let dates = [dateInAugust, dateInJune, secondDateInJune]
        let text = helper.generateLabelText(for: dates, timeRange: .thisWeek, siteTimezone: TimeZone(identifier: "GMT")!)
        let textOfDateInAugust = text[0]
        let textOfFirstDateInJune = text[1]
        let textOfSecondDateInJune = text[2]
        XCTAssertEqual(textOfDateInAugust, dayMonthFormatter.string(from: dateInAugust))
        XCTAssertEqual(textOfFirstDateInJune, dayMonthFormatter.string(from: dateInJune))
        XCTAssertEqual(textOfSecondDateInJune, dayOfMonthFormatter.string(from: secondDateInJune))
    }
}
