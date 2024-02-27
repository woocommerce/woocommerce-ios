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

    func testUserAgentFormat() throws {
        let regex = #"^Mozilla/5\.0 \([a-zA-Z]+; CPU [\sa-zA-Z]+ [_0-9]+ like Mac OS X\) AppleWebKit/605\.1\.15 \(KHTML, like Gecko\) Mobile/15E148$"#
        let regulardExpression = try NSRegularExpression(pattern: regex)
        let userAgent = UserAgent.webkitUserAgent
        XCTAssertEqual(regulardExpression.numberOfMatches(in: userAgent, range: NSMakeRange(0, userAgent.count)), 1)
    }

}
