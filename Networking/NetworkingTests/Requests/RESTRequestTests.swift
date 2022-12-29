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
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: .post, path: sampleRPC)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_it_uses_JSON_encoding_for_put_method() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: .put, path: sampleRPC)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_it_uses_URL_encoding_for_methods_other_than_post_and_put() throws {
        // Given
        let method: HTTPMethod = try XCTUnwrap([.options, .get, .head, .patch, .delete, .trace, .connect].randomElement())
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: method, path: sampleRPC)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=utf-8")
    }
}
