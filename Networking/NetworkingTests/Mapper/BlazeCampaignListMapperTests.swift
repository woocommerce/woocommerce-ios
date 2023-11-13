import XCTest
@testable import Networking

final class BlazeCampaignListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_BlazeCampaignListMapper_parses_all_contents_in_response() throws {
        let campaigns = try mapLoadBlazeCampaignListResponse()
        XCTAssertEqual(campaigns.count, 1)

        let item = try XCTUnwrap(campaigns.first)
        XCTAssertEqual(item.siteID, dummySiteID)
        XCTAssertEqual(item.campaignID, 34518)
        XCTAssertEqual(item.productID, 134)
        XCTAssertEqual(item.name, "Fried-egg Bacon Bagel")
        XCTAssertEqual(item.uiStatus, "rejected")
        XCTAssertEqual(item.contentClickURL, "https://example.com/product/fried-egg-bacon-bagel/")
        XCTAssertEqual(item.contentImageURL, "https://exampl.com/image?w=600&zoom=2")
        XCTAssertEqual(item.totalBudget, 35)
        XCTAssertEqual(item.totalClicks, 0)
        XCTAssertEqual(item.totalImpressions, 0)
    }
}

// MARK: - Test Helpers
///
private extension BlazeCampaignListMapperTests {

    /// Returns the BlazeCampaignListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapBlazeCampaignList(from filename: String) throws -> [BlazeCampaign] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try BlazeCampaignListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the BlazeCampaignListMapper output from `blaze-campaigns-success.json`
    ///
    func mapLoadBlazeCampaignListResponse() throws -> [BlazeCampaign] {
        return try mapBlazeCampaignList(from: "blaze-campaigns-success")
    }
}
