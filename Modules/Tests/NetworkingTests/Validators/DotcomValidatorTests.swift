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
