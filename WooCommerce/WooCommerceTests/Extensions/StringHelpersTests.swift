import XCTest
@testable import WooCommerce

/// String+Helpers: Unit Tests
///
final class StringHelpersTests: XCTestCase {
    func test_compare_as_version() {
        let tests = [
            VersionTestCase(foundVersion: "2.8", requiredMinimumVersion: "2", meetsMinimum: true),
            VersionTestCase(foundVersion: "2.9", requiredMinimumVersion: "3", meetsMinimum: false),
            VersionTestCase(foundVersion: "2.9.1", requiredMinimumVersion: "2", meetsMinimum: true),
            VersionTestCase(foundVersion: "3.0", requiredMinimumVersion: "3", meetsMinimum: true),

            VersionTestCase(foundVersion: "2.8", requiredMinimumVersion: "2.9", meetsMinimum: false),
            VersionTestCase(foundVersion: "2.9", requiredMinimumVersion: "2.9", meetsMinimum: true),
            VersionTestCase(foundVersion: "2.9.1", requiredMinimumVersion: "2.9", meetsMinimum: true),
            VersionTestCase(foundVersion: "3.0", requiredMinimumVersion: "2.9", meetsMinimum: true),

            VersionTestCase(foundVersion: "2.9", requiredMinimumVersion: "2.9.0", meetsMinimum: true),

            VersionTestCase(foundVersion: "2.9.1", requiredMinimumVersion: "2.9.1", meetsMinimum: true),
            VersionTestCase(foundVersion: "3.0", requiredMinimumVersion: "2.9.1", meetsMinimum: true),

            VersionTestCase(foundVersion: "3.3.1-test-1", requiredMinimumVersion: "2.9.1", meetsMinimum: true),
            VersionTestCase(foundVersion: "3.3.1-test-1", requiredMinimumVersion: "3.3", meetsMinimum: true),
            VersionTestCase(foundVersion: "3.3.1-test-1", requiredMinimumVersion: "3.3.1", meetsMinimum: true),
        ]

        for test in tests {
            let meetsMinimum = test.foundVersion.compareAsVersion(to: test.requiredMinimumVersion) != .orderedAscending
            XCTAssertEqual(test.meetsMinimum, meetsMinimum)
        }
    }

    struct VersionTestCase {
        var foundVersion: String
        var requiredMinimumVersion: String
        var meetsMinimum: Bool
    }
}
