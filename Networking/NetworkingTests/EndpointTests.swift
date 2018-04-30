import Foundation
@testable import Networking
import XCTest


/// Endpoint Unit Tests
///
class EndpointTests: XCTestCase {

    /// Verifies that the Endpoint's generated URL starts with WordPress.com API BaseURL.
    ///
    func testEndpointUrlStartsWithWordPressBaseURL() {
        let endpoint = Endpoint(wordpressApiVersion: .mark1_1, method: "sample")
        let absoluteString = try! endpoint.asURL().absoluteString

        XCTAssertTrue(absoluteString.hasPrefix(endpoint.wordpressApiBaseURL))
    }

    /// Verifies that the Endpoint's generated URL has the API Version + Method Name as suffix.
    ///
    func testEndpointUrlEndsWithApiVersionAndMethod() {
        let methodName = "method"
        let endpoint = Endpoint(wordpressApiVersion: .mark1_1, method: methodName)
        let absoluteString = try! endpoint.asURL().absoluteString

        let expectedSuffix = endpoint.wordpressApiVersion.path + methodName
        XCTAssertTrue(absoluteString.hasSuffix(expectedSuffix))
    }
}
