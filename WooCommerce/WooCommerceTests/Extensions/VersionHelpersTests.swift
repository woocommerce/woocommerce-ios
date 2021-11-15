import XCTest
@testable import WooCommerce

/// VersionHelpers Unit Tests
///
final class VersionHelpersTests: XCTestCase {
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
            VersionTestCase(foundVersion: "3.3.1-test-1", requiredMinimumVersion: "3.3.1", meetsMinimum: false),

            VersionTestCase(foundVersion: "4.3.2RC1", requiredMinimumVersion: "4.3.2RC2", meetsMinimum: false),
            VersionTestCase(foundVersion: "4.3.2RC2", requiredMinimumVersion: "4.3.2RC1", meetsMinimum: true),

            VersionTestCase(foundVersion: "1.0.0beta", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.1beta", requiredMinimumVersion: "1.0.0", meetsMinimum: true),
            VersionTestCase(foundVersion: "1.0.0beta", requiredMinimumVersion: "1.0.0b", meetsMinimum: true),

            VersionTestCase(foundVersion: "1.0.0-dev", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-alpha", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-a", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-beta", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-b", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-RC1", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-rc1", requiredMinimumVersion: "1.0.0", meetsMinimum: false),
            VersionTestCase(foundVersion: "1.0.0-pl", requiredMinimumVersion: "1.0.0", meetsMinimum: true),
            VersionTestCase(foundVersion: "1.0.0-p1", requiredMinimumVersion: "1.0.0", meetsMinimum: true),
        ]

        for test in tests {
            let meetsMinimum = VersionHelpers.compare(test.foundVersion, test.requiredMinimumVersion) != .orderedAscending
            XCTAssertEqual(test.meetsMinimum, meetsMinimum)
        }
    }

    struct VersionTestCase {
        let foundVersion: String
        let requiredMinimumVersion: String
        let meetsMinimum: Bool
    }
}
