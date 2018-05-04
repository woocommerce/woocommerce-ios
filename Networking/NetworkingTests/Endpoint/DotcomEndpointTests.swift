import Foundation
@testable import Networking
import XCTest


/// WordPress.com Endpoint Unit Tests
///
class DotcomEndpointTests: XCTestCase {

    /// RPC Sample Method Path
    ///
    private let sampleRPC = "sample"


    /// Verifies that the Endpoint's generated URL starts with WordPress.com API BaseURL.
    ///
    func testEndpointUrlStartsWithWordPressBaseURL() {
        let endpoint = DotcomEndpoint(wordpressApiVersion: .mark1_1, path: sampleRPC)
        let absoluteString = try! endpoint.asURL().absoluteString

        XCTAssertTrue(absoluteString.hasPrefix(endpoint.wordpressApiBaseURL))
    }

    /// Verifies that the Endpoint's generated URL has the API Version + Method Name as suffix.
    ///
    func testEndpointUrlEndsWithApiVersionAndMethod() {
        let request = DotcomEndpoint(wordpressApiVersion: .mark1_1, path: sampleRPC)
        let absoluteString = try! request.asURL().absoluteString

        let expectedSuffix = request.wordpressApiVersion.path + sampleRPC
        XCTAssertTrue(absoluteString.hasSuffix(expectedSuffix))
    }
}
