import XCTest
@testable import Networking

final class SiteListMapperTests: XCTestCase {

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

    func mapLoadMalformedSiteListResponse() -> [Site] {
        return mapSiteListData(from: "sites-malformed")
    }
}
