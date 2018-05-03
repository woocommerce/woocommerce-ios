import Foundation
@testable import Networking
import XCTest


/// Endpoint Unit Tests
///
class EndpointTests: XCTestCase {

    /// RPC Sample Method Path
    ///
    private let sampleRPC = "sample"


    /// Verifies that the Endpoint's generated URL starts with WordPress.com API BaseURL.
    ///
    func testEndpointUrlStartsWithWordPressBaseURL() {
        let endpoint = Endpoint(wordpressApiVersion: .mark1_1, path: sampleRPC)
        let absoluteString = try! endpoint.asURL().absoluteString

        XCTAssertTrue(absoluteString.hasPrefix(endpoint.wordpressApiBaseURL))
    }

    /// Verifies that the Endpoint's generated URL has the API Version + Method Name as suffix.
    ///
    func testEndpointUrlEndsWithApiVersionAndMethod() {
        let endpoint = Endpoint(wordpressApiVersion: .mark1_1, path: sampleRPC)
        let absoluteString = try! endpoint.asURL().absoluteString

        let expectedSuffix = endpoint.wordpressApiVersion.path + sampleRPC
        XCTAssertTrue(absoluteString.hasSuffix(expectedSuffix))
    }
}
