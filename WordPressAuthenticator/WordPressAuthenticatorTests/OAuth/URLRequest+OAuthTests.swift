@testable import WordPressAuthenticator
import XCTest

class URLRequestOAuthTokenRequestTests: XCTestCase {

    let testURL = URL(string: "https://test.com")!

    func testUsesGivenBaseURL() throws {
        let request = try URLRequest.oauthTokenRequest(baseURL: testURL)
        XCTAssertEqual(request.url, testURL)
    }

    func testMethodPost() throws {
        let request = try URLRequest.oauthTokenRequest(baseURL: testURL)
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testContentTypeFormURLEncoded() throws {
        let request = try URLRequest.oauthTokenRequest(baseURL: testURL)
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=UTF-8"
        )
    }
}
