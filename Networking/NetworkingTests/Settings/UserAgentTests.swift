import XCTest
@testable import Networking

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
        let message = "This method for retrieveing the user agent seems to be no longer working. We need to figure out an alternative."
        XCTAssertFalse(UserAgent.webkitUserAgent.isEmpty, message)
    }
}
