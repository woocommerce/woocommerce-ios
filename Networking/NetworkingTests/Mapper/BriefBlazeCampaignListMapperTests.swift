import XCTest
@testable import Networking

final class BriefBlazeCampaignListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 12983476

    /// Verifies that the whole list is parsed.
    ///
    func test_it_parses_all_contents_in_response() throws {
        let campaigns = try mapLoadBriefBlazeCampaignListResponse()
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
    }
}

// MARK: - Test Helpers
///
private extension BriefBlazeCampaignListMapperTests {

    /// Returns the BriefBlazeCampaignListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapBriefBlazeCampaignList(from filename: String) throws -> [BriefBlazeCampaignInfo] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try BriefBlazeCampaignListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the BlazeCampaignListMapper output from `blaze-brief-campaigns-list-success`
    ///
    func mapLoadBriefBlazeCampaignListResponse() throws -> [BriefBlazeCampaignInfo] {
        return try mapBriefBlazeCampaignList(from: "blaze-brief-campaigns-list-success")
    }
}
