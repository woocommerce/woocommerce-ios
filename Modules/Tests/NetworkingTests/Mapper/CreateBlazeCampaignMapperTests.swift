import XCTest
@testable import Networking
@testable import NetworkingCore

final class CreateBlazeCampaignMapperTests: XCTestCase {

    /// Verifies that the response is parsed
    ///
    func test_CreateBlazeCampaignMapper_parses_response_without_error() throws {
        try mapLoadCreateBlazeCampaignResponse()
    }
}

// MARK: - Test Helpers
//
private extension CreateBlazeCampaignMapperTests {

    /// Returns the CreateBlazeCampaignMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapCreateBlazeCampaignResponse(from filename: String) throws {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        try CreateBlazeCampaignMapper().map(response: response)
        return
    }

    /// Returns the CreateBlazeCampaignMapper output from `blaze-create-campaign-success.json`
    ///
    func mapLoadCreateBlazeCampaignResponse() throws {
        try mapCreateBlazeCampaignResponse(from: "blaze-create-campaign-success")
        return
    }

    struct FileNotFoundError: Error {}
}
