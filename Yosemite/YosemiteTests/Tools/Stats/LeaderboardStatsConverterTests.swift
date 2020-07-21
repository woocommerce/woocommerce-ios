import XCTest
@testable import Yosemite

/// LeaderboardProductParser unit tests
///
final class LeaderboardStatsConverterTest: XCTestCase {

    func testProductIDIsInferedFromAValidHTML() {
        // Given
        let html =
        """
        <a href='https://dulces.mystagingwebsite.com/wp-admin/admin.php?page=wc-admin&path=/analytics/products&filter=single_product&products=9'>Aljafor</a>
        """

        // When
        let productID = LeaderboardStatsConverter.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertEqual(productID, 9)
    }

    func testProductIDIsNotInferedFromAnArbitraryHTML() {
        // Given
        let html =
        """
        <a href='https://dulces.mystagingwebsite.com/wp-admin/admin.php?page=wc-admin&path=/analytics/products&filter=single_product'>Aljafor</a>
        """

        // When
        let productID = LeaderboardStatsConverter.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertNil(productID)
    }

    func testProductIDIsNotInferedFromAnInvalidHTML() {
        // Given
        let html = ""

        // When
        let productID = LeaderboardStatsConverter.infeerProductID(fromHTMLString: html)

        // Then
        XCTAssertNil(productID)
    }

    func testDailyGranularityDateIsFormattedCorrectly() throws {
        // Given
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let date = try XCTUnwrap(dateFormatter.date(from: "2020-07-21T12:00:00"))

        // When
        let statsDate = LeaderboardStatsConverter.statsDateFor(date: date, using: .day)

        // Then
        XCTAssertEqual(statsDate, "2020-07-21")
    }

    func testWeeklyGranularityDateIsFormattedCorrectly() throws {
        // Given
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let date = try XCTUnwrap(dateFormatter.date(from: "2020-07-21T12:00:00"))

        // When
        let statsDate = LeaderboardStatsConverter.statsDateFor(date: date, using: .week)

        // Then
        XCTAssertEqual(statsDate, "2020-W30")
    }

    func testMonthlyGranularityDateIsFormattedCorrectly() throws {
        // Given
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let date = try XCTUnwrap(dateFormatter.date(from: "2020-07-21T12:00:00"))

        // When
        let statsDate = LeaderboardStatsConverter.statsDateFor(date: date, using: .month)

        // Then
        XCTAssertEqual(statsDate, "2020-07")
    }

    func testYearlyGranularityDateIsFormattedCorrectly() throws {
        // Given
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        let date = try XCTUnwrap(dateFormatter.date(from: "2020-07-21T12:00:00"))

        // When
        let statsDate = LeaderboardStatsConverter.statsDateFor(date: date, using: .year)

        // Then
        XCTAssertEqual(statsDate, "2020")
    }
}
