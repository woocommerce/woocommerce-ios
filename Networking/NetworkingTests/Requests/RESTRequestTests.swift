import XCTest
@testable import Networking
import Alamofire

/// RESTRequest Unit Tests
///
final class RESTRequestTests: XCTestCase {
    /// Testing API Version
    ///
    private let sampleWooApiVersion = WooAPIVersion.mark3

    /// Sample SiteID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Sample site address
    ///
    private let sampleSiteAddress = "https://wordpress.com"

    /// RPC Sample Method Path
    ///
    private let sampleRPC = "sample"

    /// Sample Parameters
    ///
    private let sampleParameters = ["some": "thing", "yo": "semite"]

    func test_it_uses_JSON_encoding_for_post_method() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: .post, path: sampleRPC, parameters: sampleParameters)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_it_uses_JSON_encoding_for_put_method() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: .put, path: sampleRPC, parameters: sampleParameters)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_it_does_not_use_JSON_encoding_for_methods_other_than_post_and_put() throws {
        // Given
        let methods: [HTTPMethod] = [.options, .get, .head, .patch, .delete, .trace, .connect]
        for method in methods {
            let request = RESTRequest(siteURL: sampleSiteAddress,
                                      wooApiVersion: sampleWooApiVersion,
                                      method: method,
                                      path: sampleRPC,
                                      parameters: sampleParameters)

            // When
            let urlRequest = try request.asURLRequest()

            // Then
            XCTAssertNotEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        }
    }
}
