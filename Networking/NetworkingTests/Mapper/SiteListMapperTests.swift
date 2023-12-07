import XCTest
@testable import Networking

final class SiteListMapperTests: XCTestCase {

    func test_site_without_can_blaze_key_is_parsed_successfully() async throws {
        // Given
        let sites = try await mapLoadSiteListResponse()

        // Then
        let second = try XCTUnwrap(sites[safe: 1])
        XCTAssertFalse(second.canBlaze)
    }

    /// `sites-malformed.json` contains a correct site and a site without options(malformed)
    ///
    func test_malformed_sites_are_evicted_from_site_list() async throws {
        // Given
        let sites = try await mapLoadMalformedSiteListResponse()

        // Then
        XCTAssertEqual(sites.count, 1)
        let site = try XCTUnwrap(sites.first)
        XCTAssertFalse(site.wasEcommerceTrial)
        XCTAssertEqual(site.plan, "business-bundle")
    }
}

private extension SiteListMapperTests {
    func mapSiteListData(from filename: String) async throws -> [Site] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await SiteListMapper().map(response: response)
    }

    func mapLoadSiteListResponse() async throws -> [Site] {
        try await mapSiteListData(from: "sites")
    }

    func mapLoadMalformedSiteListResponse() async throws -> [Site] {
        try await mapSiteListData(from: "sites-malformed")
    }

    struct FileNotFoundError: Error {}
}
