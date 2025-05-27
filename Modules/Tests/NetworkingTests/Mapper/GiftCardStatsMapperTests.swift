import XCTest
@testable import Networking


/// GiftCardStatsMapper Unit Tests
///
final class GiftCardStatsMapperTests: XCTestCase {
    private struct Constants {
        static let siteID: Int64 = 1234
    }

    /// Verifies that all of the GiftCardStatsTotals fields are parsed correctly.
    ///
    func test_gift_card_stat_fields_are_properly_parsed() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let giftCardStats = mapStatItems(from: "gift-card-stats", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(giftCardStats.siteID, Constants.siteID)
        XCTAssertEqual(giftCardStats.granularity, granularity)

        // Stats report totals are parsed
        XCTAssertEqual(giftCardStats.totals.giftCardsCount, 1)
        XCTAssertEqual(giftCardStats.totals.usedAmount, 20)
        XCTAssertEqual(giftCardStats.totals.refundedAmount, 0)
        XCTAssertEqual(giftCardStats.totals.netAmount, 20)

        // Starts report intervals are parsed
        XCTAssertEqual(giftCardStats.intervals.count, 1)
        let firstInterval = try XCTUnwrap(giftCardStats.intervals.first)
        XCTAssertEqual(firstInterval.subtotals.giftCardsCount, 1)
        XCTAssertEqual(firstInterval.subtotals.usedAmount, 20)
        XCTAssertEqual(firstInterval.subtotals.refundedAmount, 0)
        XCTAssertEqual(firstInterval.subtotals.netAmount, 20)
    }

    /// Verifies that all of the GiftCardStatsTotals fields are parsed correctly.
    ///
    func test_gift_card_stat_fields_are_properly_parsed_without_data_envelope() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let giftCardStats = mapStatItems(from: "gift-card-stats-without-data", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(giftCardStats.siteID, Constants.siteID)
        XCTAssertEqual(giftCardStats.granularity, granularity)

        // Stats report totals are parsed
        XCTAssertEqual(giftCardStats.totals.giftCardsCount, 1)
        XCTAssertEqual(giftCardStats.totals.usedAmount, 20)
        XCTAssertEqual(giftCardStats.totals.refundedAmount, 0)
        XCTAssertEqual(giftCardStats.totals.netAmount, 20)

        // Starts report intervals are parsed
        XCTAssertEqual(giftCardStats.intervals.count, 1)
        let firstInterval = try XCTUnwrap(giftCardStats.intervals.first)
        XCTAssertEqual(firstInterval.subtotals.giftCardsCount, 1)
        XCTAssertEqual(firstInterval.subtotals.usedAmount, 20)
        XCTAssertEqual(firstInterval.subtotals.refundedAmount, 0)
        XCTAssertEqual(firstInterval.subtotals.netAmount, 20)
    }
}

private extension GiftCardStatsMapperTests {
    /// Returns the GiftCardStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String, granularity: StatsGranularityV4) -> GiftCardStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! GiftCardStatsMapper(siteID: Constants.siteID,
                                        granularity: granularity).map(response: response)
    }
}
