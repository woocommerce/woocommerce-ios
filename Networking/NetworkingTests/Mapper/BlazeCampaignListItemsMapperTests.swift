import XCTest
@testable import Networking

final class BlazeCampaignListItemsMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_it_parses_all_contents_in_response() throws {
        let campaigns = try mapLoadBlazeCampaignListResponse()
        XCTAssertEqual(campaigns.count, 1)

        let item = try XCTUnwrap(campaigns.first)
        XCTAssertEqual(item.siteID, dummySiteID)
        XCTAssertEqual(item.campaignID, "34518")
        XCTAssertEqual(item.productID, 134)
        XCTAssertEqual(item.name, "Fried-egg Bacon Bagel")
        XCTAssertEqual(item.uiStatus, "rejected")
        XCTAssertEqual(item.targetUrl, "https://example.com/product/fried-egg-bacon-bagel/")
        XCTAssertEqual(item.imageURL, "https://example.com/image?w=600&zoom=2")
        XCTAssertEqual(item.totalBudget, 35)
        XCTAssertEqual(item.spentBudget, 5)
        XCTAssertEqual(item.clicks, 12)
        XCTAssertEqual(item.impressions, 34)
        XCTAssertEqual(item.budgetMode, .total)
        XCTAssertEqual(item.budgetAmount, 230)
        XCTAssertEqual(item.budgetCurrency, "USD")
        XCTAssertEqual(item.isEvergreen, true)
        XCTAssertEqual(item.durationDays, 364)
        XCTAssertEqual(item.startTime, Date(timeIntervalSince1970: 1725253083))
    }
}

// MARK: - Test Helpers
///
private extension BlazeCampaignListItemsMapperTests {

    /// Returns the BlazeCampaignListItemsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapBlazeCampaignList(from filename: String) throws -> [BlazeCampaignListItem] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try BlazeCampaignListItemsMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the BlazeCampaignListItemsMapper output from `blaze-campaigns-list-success`
    ///
    func mapLoadBlazeCampaignListResponse() throws -> [BlazeCampaignListItem] {
        return try mapBlazeCampaignList(from: "blaze-campaigns-list-success")
    }
}
