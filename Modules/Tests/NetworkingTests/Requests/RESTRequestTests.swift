import XCTest
@testable import Networking
@testable import NetworkingCore
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

    func test_request_url_is_correct() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, method: .get, path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        let expectedURL = "https://wordpress.com/?rest_route=/sample"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_request_method_is_correct() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, method: .get, path: sampleRPC)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        assertEqual(urlRequest.httpMethod, "GET")
    }

    func test_request_wooApiVersion_is_correct() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, wooApiVersion: sampleWooApiVersion, method: .get, path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        let expectedURL = "https://wordpress.com/?rest_route=/wc/v3/sample"
        assertEqual(url.absoluteString, expectedURL)
    }

    func test_request_wordPressApiVersion_is_correct() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress, wordpressApiVersion: .wpMark2, method: .get, path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        let expectedURL = "https://wordpress.com/?rest_route=/wp/v2/sample"
        assertEqual(url.absoluteString, expectedURL)
    }

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

    func test_request_body_is_empty_if_parameter_is_nil() throws {
        // Given
        let methods: [HTTPMethod] = [.post, .put]
        for method in methods {
            let request = RESTRequest(siteURL: sampleSiteAddress,
                                      wooApiVersion: sampleWooApiVersion,
                                      method: method,
                                      path: sampleRPC,
                                      parameters: nil)
            // When
            let urlRequest = try request.asURLRequest()

            // Then
            XCTAssertNil(urlRequest.httpBody)
        }
    }

    func test_request_body_is_not_empty_if_parameters_is_not_nil() throws {
        // Given
        let methods: [HTTPMethod] = [.post, .put]
        for method in methods {
            let request = RESTRequest(siteURL: sampleSiteAddress,
                                      wooApiVersion: sampleWooApiVersion,
                                      method: method,
                                      path: sampleRPC,
                                      parameters: sampleParameters)
            // When
            let urlRequest = try request.asURLRequest()

            // Then
            XCTAssertNotNil(urlRequest.httpBody)
        }
    }

    // MARK: - wordpressAPIRoot Tests

    func test_request_url_uses_wp_json_root_when_wordpressAPIRoot_is_set_to_wp_json() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wordpressAPIRoot: "https://wordpress.com/wp-json/",
                                  method: .get,
                                  path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        XCTAssertEqual(url.absoluteString, "https://wordpress.com/wp-json/sample")
    }

    func test_request_url_uses_rest_route_root_when_wordpressAPIRoot_is_set_to_rest_route() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wordpressAPIRoot: "https://wordpress.com/?rest_route=/",
                                  method: .get,
                                  path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        XCTAssertEqual(url.absoluteString, "https://wordpress.com/?rest_route=/sample")
    }

    func test_request_url_falls_back_to_rest_route_basePath_when_wordpressAPIRoot_is_nil() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wordpressAPIRoot: nil,
                                  method: .get,
                                  path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        XCTAssertEqual(url.absoluteString, "https://wordpress.com/?rest_route=/sample")
    }

    func test_request_url_with_wp_json_root_and_api_version() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wordpressAPIRoot: "https://wordpress.com/wp-json/",
                                  method: .get,
                                  path: sampleRPC)

        // When
        let url = try XCTUnwrap(request.asURLRequest().url)

        // Then
        XCTAssertEqual(url.absoluteString, "https://wordpress.com/wp-json/sample")
    }

    // MARK: - allowsCellularAccess Tests

    func test_request_with_allowsCellularAccess_true_sets_URLRequest_property() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wooApiVersion: sampleWooApiVersion,
                                  method: .get,
                                  path: sampleRPC,
                                  parameters: sampleParameters,
                                  allowsCellularAccess: true)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertTrue(urlRequest.allowsCellularAccess)
    }

    func test_request_with_allowsCellularAccess_false_sets_URLRequest_property() throws {
        // Given
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wooApiVersion: sampleWooApiVersion,
                                  method: .get,
                                  path: sampleRPC,
                                  parameters: sampleParameters,
                                  allowsCellularAccess: false)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertFalse(urlRequest.allowsCellularAccess)
    }

    func test_request_defaults_to_allowsCellularAccess_true() throws {
        // Given - no explicit allowsCellularAccess parameter
        let request = RESTRequest(siteURL: sampleSiteAddress,
                                  wooApiVersion: sampleWooApiVersion,
                                  method: .get,
                                  path: sampleRPC,
                                  parameters: sampleParameters)

        // When
        let urlRequest = try request.asURLRequest()

        // Then
        XCTAssertTrue(urlRequest.allowsCellularAccess)
    }

    func test_request_with_allowsCellularAccess_works_for_all_initializers() throws {
        // Given - Test all three initializers

        // 1. Simple initializer
        let simpleRequest = RESTRequest(siteURL: sampleSiteAddress,
                                        method: .get,
                                        path: sampleRPC,
                                        parameters: sampleParameters,
                                        allowsCellularAccess: false)

        // 2. WooApiVersion initializer
        let wooRequest = RESTRequest(siteURL: sampleSiteAddress,
                                     wooApiVersion: sampleWooApiVersion,
                                     method: .get,
                                     path: sampleRPC,
                                     parameters: sampleParameters,
                                     allowsCellularAccess: false)

        // 3. WordPressApiVersion initializer
        let wpRequest = RESTRequest(siteURL: sampleSiteAddress,
                                    wordpressApiVersion: .wpMark2,
                                    method: .get,
                                    path: sampleRPC,
                                    parameters: sampleParameters,
                                    allowsCellularAccess: false)

        // When/Then
        let simpleURLRequest = try simpleRequest.asURLRequest()
        XCTAssertFalse(simpleURLRequest.allowsCellularAccess)

        let wooURLRequest = try wooRequest.asURLRequest()
        XCTAssertFalse(wooURLRequest.allowsCellularAccess)

        let wpURLRequest = try wpRequest.asURLRequest()
        XCTAssertFalse(wpURLRequest.allowsCellularAccess)
    }
}
