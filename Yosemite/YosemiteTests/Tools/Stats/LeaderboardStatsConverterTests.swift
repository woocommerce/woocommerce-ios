import XCTest
@testable import Yosemite

/// LeaderboardProductParser unit tests
///
final class LeaderboardStatsConverterTest: XCTestCase {

    /// Sample site ID
    ///
    let siteID: Int64 = 1234

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

    func testTopProductsAreMissingFromStoredProducts() {
        // Given
        let products = (2...4).map { MockProduct().product(siteID: siteID, productID: $0) }
        let leaderboard = Self.sampleLeaderboard(productIds: Array((1...5)))

        // When
        let missingIds = LeaderboardStatsConverter.missingProductsFrom(leaderboard, in: products)

        // Then
        XCTAssertEqual(missingIds, [1, 5])
    }

    func testTopProductsAreNotMissingFromStoredProducts() {
        // Given
        let products = (1...5).map { MockProduct().product(siteID: siteID, productID: $0) }
        let leaderboard = Self.sampleLeaderboard(productIds: Array((1...5)))

        // When
        let missingIds = LeaderboardStatsConverter.missingProductsFrom(leaderboard, in: products)

        // Then
        XCTAssertTrue(missingIds.isEmpty)
    }
}

/// MARK: Test functions to generate sample data
///
private extension LeaderboardStatsConverterTest {

    static func sampleLeaderboard(productIds: [Int64]) -> Leaderboard {
        let topProducts = productIds.map { sampleTopProduct(productID: $0) }
        return Leaderboard(id: "Top Products", label: "Top Products", rows: topProducts)
    }

    static func sampleTopProduct(productID: Int64) -> LeaderboardRow {
        let productHtml = "<a href='https://store.com?products=\(productID)'>Product</a>"
        let subject = LeaderboardRowContent(display: productHtml, value: "Product")
        let quantity = LeaderboardRowContent(display: "2", value: 2)
        let total = LeaderboardRowContent(display: "10.50", value: 10.50)
        return LeaderboardRow(subject: subject, quantity: quantity, total: total)
    }
}
