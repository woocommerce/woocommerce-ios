import XCTest
@testable import Networking
@testable import NetworkingCore

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

    func test_site_hasSSOEnabled_is_parsed_successfully() throws {
        // Given
        let sites = mapLoadSiteListResponse()

        // Then
        let first = try XCTUnwrap(sites[safe: 0])
        XCTAssertTrue(first.hasSSOEnabled)

        let second = try XCTUnwrap(sites[safe: 1])
        XCTAssertFalse(second.hasSSOEnabled)
    }

    func test_http_urls_are_converted_to_https() throws {
        // Given
        let sites = mapLoadHTTPSiteListResponse()

        // Then
        let site = try XCTUnwrap(sites.first)
        XCTAssertTrue(site.url.hasPrefix("https://"), "Site URL should be converted to HTTPS")
        XCTAssertTrue(site.adminURL.hasPrefix("https://"), "Admin URL should be converted to HTTPS")
        XCTAssertTrue(site.loginURL.hasPrefix("https://"), "Login URL should be converted to HTTPS")

        XCTAssertEqual(site.url, "https://insecure-site.testing.blog")
        XCTAssertEqual(site.adminURL, "https://insecure-site.testing.blog/wp-admin/")
        XCTAssertEqual(site.loginURL, "https://insecure-site.testing.blog/wp-login.php")
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

    func mapLoadHTTPSiteListResponse() -> [Site] {
        return mapSiteListData(from: "sites-http")
    }
}
