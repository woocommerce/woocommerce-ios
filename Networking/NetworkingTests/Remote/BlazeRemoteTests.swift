import XCTest
@testable import Networking

final class BlazeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load campaigns tests

    /// Verifies that loadCampaign properly parses the response.
    ///
    func test_loadCampaigns_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-campaigns-success")

        // When
        let results = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

        // Then
        XCTAssertEqual(results.count, 1)
        let item = try XCTUnwrap(results.first)
        XCTAssertEqual(item.siteID, sampleSiteID)
        XCTAssertEqual(item.campaignID, 34518)
        XCTAssertEqual(item.name, "Fried-egg Bacon Bagel")
        XCTAssertEqual(item.uiStatus, "rejected")
        XCTAssertEqual(item.contentClickURL, "https://example.com/product/fried-egg-bacon-bagel/")
        XCTAssertEqual(item.contentImageURL, "https://exampl.com/image?w=600&zoom=2")
        XCTAssertEqual(item.budgetCents, 500)
        XCTAssertEqual(item.totalClicks, 0)
        XCTAssertEqual(item.totalImpressions, 0)
        XCTAssertEqual(item.productURL, "https://example.com/product/fried-egg-bacon-bagel/")
    }

    /// Verifies that loadCampaigns sends the correct parameters.
    ///
    func test_loadCampaigns_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-campaigns-success")

        // When
        _ = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["page"] as? Int, 1)
        XCTAssertEqual(request.parameters?["order_by"] as? String, "post_date")
        XCTAssertEqual(request.parameters?["order"] as? String, "desc")
    }

    /// Verifies that loadCampaigns properly relays Networking Layer errors.
    ///
    func test_loadCampaigns_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
}
