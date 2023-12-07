import XCTest
@testable import Networking

/// SiteSummaryStatsMapper Unit Tests
///
final class SiteSummaryStatsMapperTests: XCTestCase {

    private let sampleSiteID: Int64 = 16

    /// Verifies that all of the summary stats fields are parsed correctly
    ///
    func test_summary_stat_fields_are_properly_parsed() async throws {
        // Given
        guard let summaryStats = await mapSiteSummaryStats(from: "site-summary-stats") else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(summaryStats.siteID, sampleSiteID)
        XCTAssertEqual(summaryStats.period, .day)
        XCTAssertEqual(summaryStats.date, "2022-12-09")
        XCTAssertEqual(summaryStats.visitors, 12)
        XCTAssertEqual(summaryStats.views, 123)
    }
}

/// Private Methods.
///
private extension SiteSummaryStatsMapperTests {

    /// Returns the SiteSummaryStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapSiteSummaryStats(from filename: String) async -> SiteSummaryStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! await SiteSummaryStatsMapper(siteID: sampleSiteID).map(response: response)
    }
}
