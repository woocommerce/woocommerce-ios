import Testing
import WooFoundationCore
@testable import WooFoundation

/// VersionHelpers Unit Tests
///
struct VersionHelpersTests {
    @Test("Version comparisons match PHP behaviour", arguments: [
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

        VersionTestCase(foundVersion: "9.6.0-rc.1", requiredMinimumVersion: "9.6.0-rc.2", meetsMinimum: false),
        VersionTestCase(foundVersion: "9.6.0-rc.1", requiredMinimumVersion: "9.6.0-rc.1", meetsMinimum: true),
        VersionTestCase(foundVersion: "9.6.0-rc.2", requiredMinimumVersion: "9.6.0-rc.1", meetsMinimum: true),
    ])
    func compareAsVersion(testCase: VersionTestCase) {
        let meetsMinimum = VersionHelpers.compare(testCase.foundVersion, testCase.requiredMinimumVersion) != .orderedAscending
        #expect(testCase.meetsMinimum == meetsMinimum,
                "\(testCase.foundVersion) should \(testCase.meetsMinimum ? "not " : "" )meet minimum \(testCase.requiredMinimumVersion)")
    }

    @Test("Version comparisons with includesDevAndBetaVersions", arguments: [
        VersionTestCase(foundVersion: "5.0.0-beta1", requiredMinimumVersion: "5.0.0", meetsMinimum: true),
        VersionTestCase(foundVersion: "5.0.0-dev", requiredMinimumVersion: "5.0.0", meetsMinimum: true),
        VersionTestCase(foundVersion: "5.0.0-alpha1", requiredMinimumVersion: "5.0.0", meetsMinimum: true),
        VersionTestCase(foundVersion: "5.0.0-rc1", requiredMinimumVersion: "5.0.0", meetsMinimum: true),
        VersionTestCase(foundVersion: "5.0.0-beta1", requiredMinimumVersion: "5.1.0", meetsMinimum: false),
        VersionTestCase(foundVersion: "5.0.0-dev", requiredMinimumVersion: "5.1.0", meetsMinimum: false),
        VersionTestCase(foundVersion: "5.0.0-beta1", requiredMinimumVersion: "4.9.0", meetsMinimum: true),
        VersionTestCase(foundVersion: "5.0.0-dev", requiredMinimumVersion: "4.9.0", meetsMinimum: true),
    ])
    func compareWithDevAndBetaVersions(testCase: VersionTestCase) {
        let meetsMinimum = VersionHelpers.isVersionSupported(
            version: testCase.foundVersion,
            minimumRequired: testCase.requiredMinimumVersion,
            includesDevAndBetaVersions: true
        )
        #expect(testCase.meetsMinimum == meetsMinimum,
                "\(testCase.foundVersion) should \(testCase.meetsMinimum ? "not " : "" )meet minimum \(testCase.requiredMinimumVersion)")
    }

    struct VersionTestCase {
        let foundVersion: String
        let requiredMinimumVersion: String
        let meetsMinimum: Bool
    }
}
