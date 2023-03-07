import XCTest
@testable import WooCommerce

final class StoreStatsV4ChartAxisHelperTests: XCTestCase {
    private let helper = StoreStatsV4ChartAxisHelper()

    // MARK: - Today

    func test_generateLabelText_for_today_contains_hour_text() throws {
        // Given
        // GMT: Wednesday, January 5, 2022 12:50:05 AM
        let dateAt12AM = Date(timeIntervalSince1970: 1641343805)
        // GMT: Wednesday, January 5, 2022 5:50:05 PM
        let dateAt5PM = Date(timeIntervalSince1970: 1641405005)
        let dates = [dateAt12AM, dateAt5PM]
        let timezone = try XCTUnwrap(TimeZone(identifier: "GMT"))

        // When
        let text = helper.generateLabelText(for: dates, timeRange: .today, siteTimezone: timezone)

        // Then
        // "12 AM" in en-US locale.
        XCTAssertEqual(text[0], todayXAxisFormatter(timezone: timezone).string(from: dateAt12AM))
        // "5 PM" in en-US locale.
        XCTAssertEqual(text[1], todayXAxisFormatter(timezone: timezone).string(from: dateAt5PM))
    }

    // MARK: - This Week

    func test_generateLabelText_for_thisWeek_with_dates_across_two_months_contains_month_text_for_first_different_month() {
        // Given
        // GMT: Saturday, June 1, 2019 12:29:29 AM
        let dateInJune = Date(timeIntervalSince1970: 1559348969)
        // GMT: Monday, June 10, 2019 12:29:29 AM
        let secondDateInJune = Date(timeIntervalSince1970: 1560126569)
        // GMT: Thursday, August 1, 2019 12:29:29 AM
        let dateInAugust = Date(timeIntervalSince1970: 1564619369)
        let dates = [dateInAugust, dateInJune, secondDateInJune]
        let timezone = TimeZone(identifier: "GMT")!

        // When
        let text = helper.generateLabelText(for: dates, timeRange: .thisWeek, siteTimezone: timezone)

        // Then
        let textOfDateInAugust = text[0]
        let textOfFirstDateInJune = text[1]
        let textOfSecondDateInJune = text[2]
        XCTAssertEqual(textOfDateInAugust, dayMonthFormatter(timezone: timezone).string(from: dateInAugust))
        XCTAssertEqual(textOfFirstDateInJune, dayMonthFormatter(timezone: timezone).string(from: dateInJune))
        XCTAssertEqual(textOfSecondDateInJune, dayOfMonthFormatter(timezone: timezone).string(from: secondDateInJune))
    }

    func test_generateLabelText_for_thisWeek_with_dates_in_the_same_month_only_contains_month_text_for_the_first_date() throws {
        // Given
        // GMT: Wednesday, January 5, 2022 12:50:05 AM
        let dateOnJan5 = Date(timeIntervalSince1970: 1641343805)
        // GMT: Wednesday, January 12, 2022 5:50:05 PM
        let dateOnJan12 = Date(timeIntervalSince1970: 1642009805)
        let dates = [dateOnJan12, dateOnJan5]
        let timezone = try XCTUnwrap(TimeZone(identifier: "GMT"))

        // When
        let text = helper.generateLabelText(for: dates, timeRange: .thisWeek, siteTimezone: timezone)

        // Then
        // "Jan 12" in en-US locale.
        XCTAssertEqual(text[0], dayMonthFormatter(timezone: timezone).string(from: dateOnJan12))
        // "5" in en-US locale (no month text).
        XCTAssertEqual(text[1], dayOfMonthFormatter(timezone: timezone).string(from: dateOnJan5))
    }

    // MARK: - This Month

    func test_generateLabelText_for_thisMonth_only_contains_month_text_for_the_first_date() throws {
        // Given
        // GMT: Wednesday, January 5, 2022 12:50:05 AM
        let dateOnJan5 = Date(timeIntervalSince1970: 1641343805)
        // GMT: Wednesday, January 12, 2022 5:50:05 PM
        let dateOnJan12 = Date(timeIntervalSince1970: 1642009805)
        let dates = [dateOnJan12, dateOnJan5]
        let timezone = try XCTUnwrap(TimeZone(identifier: "GMT"))

        // When
        let text = helper.generateLabelText(for: dates, timeRange: .thisMonth, siteTimezone: timezone)

        // Then
        // "Jan 12" in en-US locale.
        XCTAssertEqual(text[0], dayMonthFormatter(timezone: timezone).string(from: dateOnJan12))
        // "5" in en-US locale (no month text).
        XCTAssertEqual(text[1], dayOfMonthFormatter(timezone: timezone).string(from: dateOnJan5))
    }

    // MARK: - This Year

    func test_generateLabelText_for_thisYear_has_month_text_for_all_dates() throws {
        // Given
        // GMT: Friday, March 11, 2022 5:50:05 PM
        let dateInMarch = Date(timeIntervalSince1970: 1647021005)
        // GMT: Wednesday, January 12, 2022 5:50:05 PM
        let dateInJan = Date(timeIntervalSince1970: 1642009805)
        let dates = [dateInMarch, dateInJan]
        let timezone = try XCTUnwrap(TimeZone(identifier: "GMT"))

        // When
        let text = helper.generateLabelText(for: dates, timeRange: .thisYear, siteTimezone: timezone)

        // Then
        // "Mar" in en-US locale.
        XCTAssertEqual(text[0], monthFormatter(timezone: timezone).string(from: dateInMarch))
        // "Jan" in en-US locale (no month text).
        XCTAssertEqual(text[1], monthFormatter(timezone: timezone).string(from: dateInJan))
    }
}

private extension StoreStatsV4ChartAxisHelperTests {
    func dayOfMonthFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d")
        formatter.timeZone = timezone
        return formatter
    }

    func dayMonthFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        formatter.timeZone = timezone
        return formatter
    }

    func monthFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        formatter.timeZone = timezone
        return formatter
    }

    func todayXAxisFormatter(timezone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("ha")
        formatter.timeZone = timezone
        return formatter
    }
}
