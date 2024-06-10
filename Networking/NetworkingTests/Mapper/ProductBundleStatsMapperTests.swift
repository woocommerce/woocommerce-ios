import XCTest
@testable import Networking


/// ProductBundleStatsMapper Unit Tests
///
final class ProductBundleStatsMapperTests: XCTestCase {
    private struct Constants {
        static let siteID: Int64 = 1234
    }

    /// Verifies that all of the ProductBundleStatsTotals fields are parsed correctly.
    ///
    func test_product_bundle_stat_fields_are_properly_parsed() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let bundleStats = mapStatItems(from: "product-bundle-stats", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(bundleStats.siteID, Constants.siteID)
        XCTAssertEqual(bundleStats.granularity, .daily)

        // Stats report totals are parsed
        XCTAssertEqual(bundleStats.totals.totalItemsSold, 5)
        XCTAssertEqual(bundleStats.totals.totalBundledItemsSold, 3)
        XCTAssertEqual(bundleStats.totals.netRevenue, 50)
        XCTAssertEqual(bundleStats.totals.totalOrders, 2)
        XCTAssertEqual(bundleStats.totals.totalProducts, 4)

        // Starts report intervals are parsed
        XCTAssertEqual(bundleStats.intervals.count, 2)
        let firstInterval = try XCTUnwrap(bundleStats.intervals.first)
        XCTAssertEqual(firstInterval.subtotals.totalItemsSold, 3)
        XCTAssertEqual(firstInterval.subtotals.totalBundledItemsSold, 2)
        XCTAssertEqual(firstInterval.subtotals.netRevenue, 35)
        XCTAssertEqual(firstInterval.subtotals.totalOrders, 1)
        XCTAssertEqual(firstInterval.subtotals.totalProducts, 2)
    }

    /// Verifies that all of the ProductBundleStatsTotals fields are parsed correctly.
    ///
    func test_product_bundle_stat_fields_are_properly_parsed_without_data_envelope() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let bundleStats = mapStatItems(from: "product-bundle-stats-without-data", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(bundleStats.siteID, Constants.siteID)
        XCTAssertEqual(bundleStats.granularity, .daily)

        // Stats report totals are parsed
        XCTAssertEqual(bundleStats.totals.totalItemsSold, 5)
        XCTAssertEqual(bundleStats.totals.totalBundledItemsSold, 3)
        XCTAssertEqual(bundleStats.totals.netRevenue, 50)
        XCTAssertEqual(bundleStats.totals.totalOrders, 2)
        XCTAssertEqual(bundleStats.totals.totalProducts, 4)

        // Starts report intervals are parsed
        XCTAssertEqual(bundleStats.intervals.count, 2)
        let firstInterval = try XCTUnwrap(bundleStats.intervals.first)
        XCTAssertEqual(firstInterval.subtotals.totalItemsSold, 3)
        XCTAssertEqual(firstInterval.subtotals.totalBundledItemsSold, 2)
        XCTAssertEqual(firstInterval.subtotals.netRevenue, 35)
        XCTAssertEqual(firstInterval.subtotals.totalOrders, 1)
        XCTAssertEqual(firstInterval.subtotals.totalProducts, 2)
    }
}

private extension ProductBundleStatsMapperTests {
    /// Returns the ProductBundleStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String, granularity: StatsGranularityV4) -> ProductBundleStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ProductBundleStatsMapper(siteID: Constants.siteID,
                                             granularity: granularity).map(response: response)
    }
}
