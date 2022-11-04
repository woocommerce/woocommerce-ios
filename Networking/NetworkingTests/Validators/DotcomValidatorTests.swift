import XCTest
@testable import Networking


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
            XCTAssertEqual(dotcomError, .unauthorized)
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
            XCTAssertEqual(dotcomError, .noRestRoute)
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
            XCTAssertEqual(dotcomError, .noStatsPermission)
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
            XCTAssertEqual(dotcomError, .statsModuleDisabled)
        }
    }
}
