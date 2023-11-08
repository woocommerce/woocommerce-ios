import XCTest
@testable import Networking

final class SiteListMapperTests: XCTestCase {

    func test_site_without_can_blaze_key_is_parsed_successfully() throws {
        // Given
        let sites = mapLoadSiteListResponse()

        // Then
        let second = try XCTUnwrap(sites[safe: 1])
        XCTAssertFalse(second.canBlaze)
    }

    /// `sites-malformed.json` contains a correct site and a site without options(malformed)
    ///
    func test_malformed_sites_are_evicted_from_site_list() throws {
        // Given
        let sites = mapLoadMalformedSiteListResponse()

        // Then
        XCTAssertEqual(sites.count, 1)
        let site = try XCTUnwrap(sites.first)
        XCTAssertFalse(site.wasEcommerceTrial)
        XCTAssertEqual(site.plan, "business-bundle")
    }
}

private extension SiteListMapperTests {
    func mapSiteListData(from filename: String) -> [Site] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return (try? SiteListMapper().map(response: response)) ?? []
    }

    func mapLoadSiteListResponse() -> [Site] {
        mapSiteListData(from: "sites")
    }

    func mapLoadMalformedSiteListResponse() -> [Site] {
        return mapSiteListData(from: "sites-malformed")
    }
}
