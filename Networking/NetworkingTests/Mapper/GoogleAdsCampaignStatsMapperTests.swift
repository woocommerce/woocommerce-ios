import XCTest
@testable import Networking


/// GoogleAdsCampaignStatsMapper Unit Tests
///
final class GoogleAdsCampaignStatsMapperTests: XCTestCase {
    private struct Constants {
        static let siteID: Int64 = 1234
    }

    /// Verifies that all of the GoogleAdsCampaignStats fields are parsed correctly.
    ///
    func test_goodle_ads_campaign_stat_fields_are_properly_parsed() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let adsCampaignStats = mapStatItems(from: "google-ads-reports-programs", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(adsCampaignStats.siteID, Constants.siteID)
        XCTAssertFalse(adsCampaignStats.hasNextPage)

        // Stats report totals are parsed
        XCTAssertEqual(adsCampaignStats.totals.sales, 0)
        XCTAssertEqual(adsCampaignStats.totals.spend, 0)
        XCTAssertNil(adsCampaignStats.totals.clicks)
        XCTAssertNil(adsCampaignStats.totals.impressions)
        XCTAssertNil(adsCampaignStats.totals.conversions)

        // Stats report campaigns are parsed
        XCTAssertTrue(adsCampaignStats.campaigns.isEmpty)
    }

    /// Verifies that all of the GoogleAdsCampaignStats fields are parsed correctly.
    ///
    func test_google_ads_campaign_stat_fields_without_data_are_properly_parsed() throws {
        // Given
        let granularity = StatsGranularityV4.daily

        // When
        guard let adsCampaignStats = mapStatItems(from: "google-ads-reports-programs-without-data", granularity: granularity) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertEqual(adsCampaignStats.siteID, Constants.siteID)
        XCTAssertTrue(adsCampaignStats.hasNextPage)

        // Stats report totals are parsed
        XCTAssertEqual(adsCampaignStats.totals.sales, 11)
        XCTAssertEqual(adsCampaignStats.totals.spend, 73.01)
        XCTAssertEqual(adsCampaignStats.totals.clicks, 154)
        XCTAssertEqual(adsCampaignStats.totals.impressions, 16938)
        XCTAssertEqual(adsCampaignStats.totals.conversions, 3)

        // Stats report campaigns are parsed
        XCTAssertEqual(adsCampaignStats.campaigns.count, 2)
        let firstCampaign = try XCTUnwrap(adsCampaignStats.campaigns.first)
        XCTAssertEqual(firstCampaign.campaignID, 123)
        XCTAssertEqual(firstCampaign.campaignName, "One")
        XCTAssertEqual(firstCampaign.status, .enabled)
        XCTAssertEqual(firstCampaign.subtotals.sales, 11)
        XCTAssertEqual(firstCampaign.subtotals.spend, 63.14)
        XCTAssertEqual(firstCampaign.subtotals.clicks, 139)
        XCTAssertEqual(firstCampaign.subtotals.impressions, 16037)
        XCTAssertEqual(firstCampaign.subtotals.conversions, 3)
    }
}

private extension GoogleAdsCampaignStatsMapperTests {
    /// Returns the GoogleAdsCampaignStatsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStatItems(from filename: String, granularity: StatsGranularityV4) -> GoogleAdsCampaignStats? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! GoogleAdsCampaignStatsMapper(siteID: Constants.siteID).map(response: response)
    }
}
