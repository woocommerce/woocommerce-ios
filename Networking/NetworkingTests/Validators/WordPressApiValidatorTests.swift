import XCTest
@testable import Networking


/// WordPressApiValidator Unit Tests
///
class WordPressApiValidatorTests: XCTestCase {

    /// Verifies that the DotcomValidator successfully extracts the Dotcom Error contained within a `Data` instance.
    ///
    func testForbiddenErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("error-wp-rest-forbidden", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try WordPressApiValidator().validate(data: payloadAsData)) { error in
            guard let wpApiError = error as? WordPressApiError else {
                return XCTFail()
            }
            XCTAssertEqual(wpApiError, .unknown(code: "rest_forbidden", message: "Sorry, you are not allowed to do that."))
        }
    }
}
