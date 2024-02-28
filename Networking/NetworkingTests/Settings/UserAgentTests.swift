import XCTest
import WebKit

@testable import Networking

/// UserAgent Unit Tests
///
final class UserAgentTests: XCTestCase {

    let webkitUserAgentRegex = #"^Mozilla/5\.0 \([a-zA-Z]+; CPU [\sa-zA-Z]+ [_0-9]+ like Mac OS X\) AppleWebKit/605\.1\.15 \(KHTML, like Gecko\) Mobile/15E148$"#

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
        let regulardExpression = try NSRegularExpression(pattern: webkitUserAgentRegex)
        let userAgent = UserAgent.webkitUserAgent
        XCTAssertEqual(regulardExpression.numberOfMatches(in: userAgent, range: NSMakeRange(0, userAgent.count)), 1)
    }

    // If this test fails, it may mean `WKWebView` uses a user agent with an unexpected format (see `webkitUserAgentRegex`)
    // and we may need to adjust `UserAgent.webkitUserAgent`'s implementation to match `WKWebView`'s user agent.
    func testWKWebViewUserAgentFormat() throws {
        let regulardExpression = try NSRegularExpression(pattern: webkitUserAgentRegex)
        // Please note: WKWebView's user agent may be different on different test device types.
        let userAgent = try XCTUnwrap(WKWebView().value(forKey: "_userAgent") as? String)
        XCTAssertEqual(regulardExpression.numberOfMatches(in: userAgent, range: NSMakeRange(0, userAgent.count)), 1)
    }

}
