import XCTest
@testable import Networking


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
