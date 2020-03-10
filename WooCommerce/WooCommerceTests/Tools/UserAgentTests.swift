import XCTest
@testable import WooCommerce

/// UserAgent Unit Tests
///
final class UserAgentTests: XCTestCase {

    func testDefaultUserAgent() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? String()

        let defaultUserAgent = UserAgent.defaultUserAgent
        let expectedUserAgent = UserAgent.webkitUserAgent + " " + "wc-ios" + "/" + appVersion

        XCTAssertEqual(defaultUserAgent, expectedUserAgent)
    }

    func testUserAgentIsNeverEmpty() {
        XCTAssertFalse(UserAgent.webkitUserAgent.isEmpty, "This method for retrieveing the user agent seems to be no longer working. We need to figure out an alternative.")
    }
}
