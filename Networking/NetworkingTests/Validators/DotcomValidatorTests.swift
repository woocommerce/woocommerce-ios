import XCTest
@testable import Networking


/// DotcomValidator Unit Tests
///
class DotcomValidatorTests: XCTestCase {

    /// Verifies that the DotcomValidator successfully extracts the Dotcom Error contained within a `Data` instance.
    ///
    func testGenericErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("generic_error", extension: "json"),
            let dotcomError = DotcomValidator.error(from: payloadAsData) as? DotcomError
            else {
                XCTFail()
                return
        }

        XCTAssertEqual(dotcomError.error, "unknown_token")
        XCTAssertEqual(dotcomError.message, "Unknown Token")
    }
}
