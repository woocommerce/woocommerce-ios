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

        XCTAssertEqual(dotcomError.code, "unknown_token")
        XCTAssertEqual(dotcomError.message, "Unknown Token")
    }

    /// Verifies that the DotcomValidator successfully extracts the Dotcom Error contained within a JSON Document.
    ///
    func testGenericErrorIsProperlyExtractedFromJSONDocument() {
        guard let payloadAsData = Loader.contentsOf("generic_error", extension: "json"),
            let document = try? JSONSerialization.jsonObject(with: payloadAsData, options: []),
            let dotcomError = DotcomValidator.error(from: document) as? DotcomError
            else {
                XCTFail()
                return
        }

        XCTAssertEqual(dotcomError.code, "unknown_token")
        XCTAssertEqual(dotcomError.message, "Unknown Token")
    }
}
