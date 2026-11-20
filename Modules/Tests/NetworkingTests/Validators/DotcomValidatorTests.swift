import XCTest
@testable import Networking
@testable import NetworkingCore


/// DotcomValidator Unit Tests
///
class DotcomValidatorTests: XCTestCase {

    /// Verifies that the DotcomValidator successfully extracts the Dotcom Error contained within a `Data` instance.
    ///
    func testGenericErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("generic_error", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError else {
                return XCTFail()
            }
            XCTAssertEqual(dotcomError, .unauthorized())
        }
    }

    /// Verifies that the DotcomValidator successfully extracts the rest_no_route Dotcom Error contained within a `Data` instance.
    ///
    func testRestNoRouteErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("restnoroute_error", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError else {
                return XCTFail()
            }
            XCTAssertEqual(dotcomError, .noRestRoute())
        }
    }

    /// Verifies that the DotcomValidator successfully extracts the `noStatsPermission` Dotcom Error contained within a `Data` instance.
    ///
    func testNoStatsPermissionErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("no_stats_permission_error", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError else {
                return XCTFail()
            }
            XCTAssertEqual(dotcomError, .noStatsPermission())
        }
    }

    /// Verifies that the DotcomValidator successfully extracts the `unknownBlog` Dotcom Error contained within a `Data` instance.
    ///
    func testUnknownBlogErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("unknown_blog_error", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError else {
                return XCTFail()
            }
            XCTAssertEqual(dotcomError, .unknownBlog())
        }
    }

    /// Verifies that the DotcomValidator successfully extracts the `statsModuleDisabled` Dotcom Error contained within a `Data` instance.
    ///
    func testStatsModuleDisabledErrorIsProperlyExtractedFromData() {
        guard let payloadAsData = Loader.contentsOf("stats_module_disabled_error", extension: "json")
            else {
            return XCTFail()
        }

        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError else {
                return XCTFail()
            }
            XCTAssertEqual(dotcomError, .statsModuleDisabled())
        }
    }

    func test_validate_when_error_is_unknown_token_then_throws_jetpackNotConnected_with_raw_code() throws {
        // Given
        let payloadAsData = try XCTUnwrap(#"{"error": "unknown_token", "message": "Token is invalid"}"#.data(using: .utf8))

        // Then
        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError, case .jetpackNotConnected = dotcomError else {
                return XCTFail("Expected DotcomError.jetpackNotConnected")
            }
            XCTAssertEqual(dotcomError.rawCode, "unknown_token")
            XCTAssertTrue(String(reflecting: dotcomError).contains("unknown_token"))
        }
    }

    func test_validate_when_error_is_invalid_blog_without_jetpack_then_throws_jetpackNotConnected_with_raw_code() throws {
        // Given
        let payload = #"{"error": "invalid_blog", "message": "This blog does not have Jetpack connected"}"#
        let payloadAsData = try XCTUnwrap(payload.data(using: .utf8))

        // Then
        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard let dotcomError = error as? DotcomError, case .jetpackNotConnected = dotcomError else {
                return XCTFail("Expected DotcomError.jetpackNotConnected")
            }
            XCTAssertEqual(dotcomError.rawCode, "invalid_blog")
            XCTAssertTrue(String(reflecting: dotcomError).contains("invalid_blog"))
        }
    }

    func test_equality_when_jetpackNotConnected_codes_differ_then_errors_are_equal() {
        // Given
        let userTokenError = DotcomError.jetpackNotConnected(code: "unknown_token")
        let siteError = DotcomError.jetpackNotConnected(code: "invalid_blog")

        // Then
        XCTAssertEqual(userTokenError, siteError)
        XCTAssertEqual(userTokenError, .jetpackNotConnected())
    }

    func test_debugDescription_when_error_has_no_raw_code_then_returns_description() {
        // Given
        let error = DotcomError.empty()

        // Then
        XCTAssertNil(error.rawCode)
        XCTAssertEqual(String(reflecting: error), error.description)
    }

    func test_debugDescription_when_error_has_raw_code_then_appends_code_to_description() {
        // Given
        let error = DotcomError.jetpackNotConnected(code: "unknown_token")

        // Then
        XCTAssertEqual(String(reflecting: error), "\(error.description) (code: unknown_token)")
    }

    func test_rawCode_when_error_is_mapped_then_returns_server_identifier() {
        // Given
        let expectedCodes: [(DotcomError, String?)] = [
            (.empty(), nil),
            (.unauthorized(), "unauthorized"),
            (.invalidToken(), "invalid_token"),
            (.requestFailed(), "http_request_failed"),
            (.noRestRoute(), "rest_no_route"),
            (.jetpackNotConnected(), nil),
            (.jetpackNotConnected(code: "unknown_token"), "unknown_token"),
            (.jetpackNotConnected(code: "invalid_blog"), "invalid_blog"),
            (.unknownBlog(), "unknown_blog"),
            (.invalidSignature(), "rest_invalid_signature"),
            (.unknown(code: "custom_error", message: nil, data: nil), "custom_error"),
            (.noStatsPermission(), "unauthorized"),
            (.statsModuleDisabled(), "invalid_blog"),
            (.resourceDoesNotExist(), "woocommerce_rest_term_invalid")
        ]

        // Then
        for (error, expectedCode) in expectedCodes {
            XCTAssertEqual(error.rawCode, expectedCode, "Unexpected rawCode for \(error)")
        }
    }

    func test_rawCode_when_error_is_decoded_then_matches_server_identifier() throws {
        // Given
        let payloads: [(String, String)] = [
            (#"{"error": "unauthorized", "message": "user cannot view stats"}"#, "unauthorized"),
            (#"{"error": "invalid_blog", "message": "This blog does not have the Stats module enabled"}"#, "invalid_blog"),
            (#"{"error": "woocommerce_rest_term_invalid", "message": "Resource does not exist."}"#, "woocommerce_rest_term_invalid"),
            (#"{"error": "some_new_error", "message": "Something went wrong"}"#, "some_new_error"),
            (#"{"code": "rest_invalid_signature", "message": "Invalid signature"}"#, "rest_invalid_signature")
        ]

        for (payload, expectedCode) in payloads {
            let payloadAsData = try XCTUnwrap(payload.data(using: .utf8))

            // When
            let error = try JSONDecoder().decode(DotcomError.self, from: payloadAsData)

            // Then
            XCTAssertEqual(error.rawCode, expectedCode, "Unexpected rawCode for \(payload)")
        }
    }

    func test_raw_body_error_preserves_data_raw_body() throws {
        // Given
        let payloadAsData = try XCTUnwrap(Loader.contentsOf("jetpack-tunnel-raw-body-error", extension: "json"))

        // Then
        XCTAssertThrowsError(try DotcomValidator().validate(data: payloadAsData)) { error in
            guard case let DotcomError.unknown(code, message, data) = error else {
                return XCTFail("Expected DotcomError.unknown")
            }

            XCTAssertEqual(code, "no_response_body")
            XCTAssertEqual(message, "Server could not read response.")
            XCTAssertEqual(data?["status"]?.value as? Int, 502)
            XCTAssertEqual(
                data?["raw_body"]?.value as? String,
                "<html>\n  Fatal error consumer_key=ck_secret Authorization: Bearer bearer-secret Cookie: session=abc\n</html>"
            )
        }
    }
}
