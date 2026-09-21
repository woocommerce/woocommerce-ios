import XCTest
@testable import Networking
@testable import NetworkingCore


/// WordPressSiteMapper Unit Tests
///
final class WordPressSiteMapperTests: XCTestCase {

    func test_response_is_properly_parsed() throws {
        let site = try XCTUnwrap(mapWordPressSiteInfoResponse())
        XCTAssertEqual(site.name, "My WordPress Site")
        XCTAssertEqual(site.description, "Just another WordPress site")
        XCTAssertEqual(site.url, "https://test.com")
        XCTAssertEqual(site.gmtOffset, "0")
        XCTAssertEqual(site.timezone, "")
        XCTAssertFalse(site.namespaces.isEmpty)
        XCTAssertFalse(site.isWooCommerceActive)
    }

    func test_asSite_normalizes_http_url_and_records_that_normalization_was_required() {
        // Given
        let originalURL = "http://example.com"

        // When
        let site = WordPressSite(name: "Store",
                                 description: "Description",
                                 url: originalURL,
                                 timezone: "UTC",
                                 gmtOffset: "0",
                                 namespaces: [],
                                 applicationPasswordAuthorizationURL: nil).asSite

        // Then
        XCTAssertEqual(site.url, "https://example.com")
        XCTAssertEqual(site.adminURL, "https://example.com/wp-admin/")
        XCTAssertEqual(site.loginURL, "https://example.com/wp-login.php")
        XCTAssertEqual(site.wasURLNormalizedToHTTPS, true)
    }
}

// MARK: - Private Methods.
//
private extension WordPressSiteMapperTests {

    /// Returns the WordPressSiteMapper output upon receiving success response
    ///
    func mapWordPressSiteInfoResponse() -> WordPressSite? {
        guard let response = Loader.contentsOf("wordpress-site-info") else {
            return nil
        }

        return try? WordPressSiteMapper().map(response: response)
    }
}
