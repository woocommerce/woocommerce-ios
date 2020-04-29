import XCTest
@testable import Networking


/// SitePostMapper Unit Tests
///
final class SitePostMapperTests: XCTestCase {

    /// Verifies that all of the SitePost fields are parsed correctly.
    ///
    func testFieldsAreProperlyParsed() {
        guard let sitePost = mapSitePost() else {
            XCTFail()
            return
        }

        XCTAssertEqual(sitePost.siteID, 3584907)
        XCTAssertEqual(sitePost.password, "woooooooo!")
    }
}


/// Private Methods.
///
private extension SitePostMapperTests {

    /// Returns the SitePostMapper output upon receiving `site-post` json (Data Encoded)
    ///
    func mapSitePost() -> SitePost? {
        guard let response = Loader.contentsOf("site-post") else {
            return nil
        }

        return try! SitePostMapper().map(response: response)
    }
}
