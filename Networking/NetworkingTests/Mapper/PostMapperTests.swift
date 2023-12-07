import XCTest
@testable import Networking


/// PostMapper Unit Tests
///
final class PostMapperTests: XCTestCase {

    /// Verifies that all of the Post fields are parsed correctly.
    ///
    func test_fields_are_properly_parsed() async {
        guard let sitePost = await mapSitePost() else {
            XCTFail()
            return
        }

        XCTAssertEqual(sitePost.siteID, 3584907)
        XCTAssertEqual(sitePost.password, "woooooooo!")
    }
}


/// Private Methods.
///
private extension PostMapperTests {

    /// Returns the PostMapper output upon receiving `site-post` json (Data Encoded)
    ///
    func mapSitePost() async -> Post? {
        guard let response = Loader.contentsOf("site-post") else {
            return nil
        }

        return try! await PostMapper().map(response: response)
    }
}
