import XCTest

@testable import Networking

private extension URLRequest {
    var httpBodyString: String? {
        return httpBody.flatMap({ data in
            return String(data: data, encoding: .utf8)
        })
    }
}

final class WebViewAuthenticatorTests: XCTestCase {
    let dotComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!
    let dotComUser = "comuser"
    let dotComToken = "comtoken"

    var dotComAuthenticator: WebViewAuthenticator {
        let credentials = Credentials(username: dotComUser, authToken: dotComToken, siteAddress: "")
        return WebViewAuthenticator(credentials: credentials)
    }

    func testAuthenticatedDotComRequestWithoutCookie() {
        let expectedRedirect = "https://wordpress.com/?wpios_redirect%3Dhttps://example.wordpress.com/some-page/"
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar()
        var authenticatedRequest: URLRequest? = nil
        authenticator.request(url: url, cookieJar: cookieJar) {
            authenticatedRequest = $0
        }
        guard let request = authenticatedRequest else {
            XCTFail("The authenticator should return a valid request")
            return
        }
        XCTAssertEqual(request.url, dotComLoginURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(dotComToken)")
        XCTAssertEqual(request.httpBodyString, "log=\(dotComUser)&rememberme=true&redirect_to=\(expectedRedirect)")
    }

    func testUnauthenticatedDotComRequestWithCookie() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator

        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)
        var authenticatedRequest: URLRequest? = nil
        authenticator.request(url: url, cookieJar: cookieJar) {
            authenticatedRequest = $0
        }
        guard let request = authenticatedRequest else {
            XCTFail("The authenticator should return a valid request")
            return
        }
        XCTAssertEqual(request.url, url)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

}
