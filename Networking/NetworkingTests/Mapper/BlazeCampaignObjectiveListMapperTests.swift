import XCTest
@testable import Networking

final class BlazeCampaignObjectiveListMapperTests: XCTestCase {

    /// Verifies that the campaign objectives are parsed.
    ///
    func test_BlazeCampaignObjectiveListMapper_parses_all_contents_in_response() throws {
        // When
        let locale = "vi"
        let objectives = try XCTUnwrap(mapLoadBlazeCampaignObjectiveListResponse(locale: locale))
        let expectedObjectives = [
            BlazeCampaignObjective(id: "traffic",
                                   title: "Traffic",
                                   description: "Aims to drive more visitors and increase page views.",
                                   suitableForDescription: "E-commerce sites, content-driven websites, startups.",
                                   locale: locale),
            BlazeCampaignObjective(id: "sales",
                                   title: "Sales",
                                   description: "Converts potential customers into buyers by encouraging purchase.",
                                   suitableForDescription: "E-commerce, retailers, subscription services.",
                                   locale: locale),
            BlazeCampaignObjective(id: "awareness",
                                   title: "Awareness",
                                   description: "Focuses on increasing brand recognition and visibility.",
                                   suitableForDescription: "New businesses, brands launching new products.",
                                   locale: locale),
            BlazeCampaignObjective(id: "engagement",
                                   title: "Engagement",
                                   description: "Encourages your audience to interact and connect with your brand.",
                                   suitableForDescription: "Influencers and community builders looking for followers of the same interest.",
                                   locale: locale)
        ]

        // Then
        XCTAssertEqual(objectives, expectedObjectives)
    }

}

private extension BlazeCampaignObjectiveListMapperTests {
    /// Returns the [BlazeCampaignObjective] output from `blaze-campaign-objectives.json`
    ///
    func mapLoadBlazeCampaignObjectiveListResponse(locale: String) throws -> [BlazeCampaignObjective] {
        guard let response = Loader.contentsOf("blaze-campaign-objectives") else {
            return []
        }
        return try BlazeCampaignObjectiveListMapper(locale: locale).map(response: response)
    }
}
