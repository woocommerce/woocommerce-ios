import XCTest
@testable import Networking

final class GoogleAdsCampaignListMapperTests: XCTestCase {

    func test_google_ads_campaign_list_is_properly_parsed_with_data_envelope() throws {
        // When
        let campaigns = try mapGoogleAdsCampaignList(from: "gla-campaign-list-with-data-envelope")

        // Then
        XCTAssertEqual(campaigns.count, 2)
        let firstItem = try XCTUnwrap(campaigns.first)
        XCTAssertEqual(firstItem.id, 21401695859)
        XCTAssertEqual(firstItem.name, "Campaign 2024-06-21 04:26:32")
        XCTAssertEqual(firstItem.rawStatus, "enabled")
        XCTAssertEqual(firstItem.rawType, "performance_max")
        XCTAssertEqual(firstItem.amount, 10)
        XCTAssertEqual(firstItem.country, "US")
        XCTAssertEqual(firstItem.targetedLocations, ["US"])
        XCTAssertEqual(firstItem.status, .enabled)

        let secondItem = try XCTUnwrap(campaigns.last)
        XCTAssertEqual(secondItem.id, 21402492606)
        XCTAssertEqual(secondItem.name, "Campaign 2024-06-24 05:08:41")
        XCTAssertEqual(secondItem.rawStatus, "disabled")
        XCTAssertEqual(secondItem.rawType, "performance_max")
        XCTAssertEqual(secondItem.amount, 30)
        XCTAssertEqual(secondItem.country, "US")
        XCTAssertEqual(secondItem.targetedLocations, ["US"])
        XCTAssertEqual(secondItem.status, .disabled)
    }

    func test_google_ads_campaign_list_is_properly_parsed_without_data_envelope() throws {
        // When
        let campaigns = try mapGoogleAdsCampaignList(from: "gla-campaign-list-without-data-envelope")

        // Then
        XCTAssertEqual(campaigns.count, 2)
        let firstItem = try XCTUnwrap(campaigns.first)
        XCTAssertEqual(firstItem.id, 21401695859)
        XCTAssertEqual(firstItem.name, "Campaign 2024-06-21 04:26:32")
        XCTAssertEqual(firstItem.rawStatus, "enabled")
        XCTAssertEqual(firstItem.rawType, "performance_max")
        XCTAssertEqual(firstItem.amount, 10)
        XCTAssertEqual(firstItem.country, "US")
        XCTAssertEqual(firstItem.targetedLocations, ["US"])
        XCTAssertEqual(firstItem.status, .enabled)

        let secondItem = try XCTUnwrap(campaigns.last)
        XCTAssertEqual(secondItem.id, 21402492606)
        XCTAssertEqual(secondItem.name, "Campaign 2024-06-24 05:08:41")
        XCTAssertEqual(secondItem.rawStatus, "disabled")
        XCTAssertEqual(secondItem.rawType, "performance_max")
        XCTAssertEqual(secondItem.amount, 30)
        XCTAssertEqual(secondItem.country, "US")
        XCTAssertEqual(secondItem.targetedLocations, ["US"])
        XCTAssertEqual(secondItem.status, .disabled)
    }
}

private extension GoogleAdsCampaignListMapperTests {
    /// Returns the [GoogleAdsCampaign] output upon receiving `filename` (Data Encoded)
    ///
    func mapGoogleAdsCampaignList(from filename: String) throws -> [GoogleAdsCampaign] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try GoogleAdsCampaignListMapper().map(response: response)
    }
}
