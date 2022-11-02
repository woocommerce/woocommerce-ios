import XCTest
@testable import WooCommerce

private extension URLRequest {
    var httpBodyString: String? {
        return httpBody.flatMap({ data in
            return String(data: data, encoding: .utf8)
        })
    }
}

class RequestAuthenticatorTests: XCTestCase {
    let dotComLoginURL = URL(string: "https://wordpress.com/wp-login.php")!
    let dotComUser = "comuser"
    let dotComToken = "comtoken"
    let siteLoginURL = URL(string: "https://example.com/wp-login.php")!
    let siteUser = "siteuser"
    let sitePassword = "x>73R9&9;r&ju9$J499FmZ?2*Nii/?$8"
    let sitePasswordEncoded = "x%3E73R9%269;r%26ju9$J499FmZ?2*Nii/?$8"

    var dotComAuthenticator: RequestAuthenticator {
        return RequestAuthenticator(credentials: .dotCom(username: dotComUser, authToken: dotComToken, authenticationType: .regular))
    }

    var siteAuthenticator: RequestAuthenticator {
        return RequestAuthenticator(
            credentials: .siteLogin(loginURL: siteLoginURL, username: siteUser, password: sitePassword))
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

    func testDecideActionForNavigationResponse() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.allow)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }

    func testDecideActionForNavigationResponse_RemoteLoginError() {
        let url = URL(string: "https://r-login.wordpress.com/remote-login.php?action=auth")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.reload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }

    func testDecideActionForNavigationResponse_ClientError() {
        let url = URL(string: "https://example.wordpress.com/some-page/")!
        let authenticator = dotComAuthenticator
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: dotComUser)

        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!

        let expectation = self.expectation(description: "Action Should be decided")
        authenticator.decideActionFor(response: response, cookieJar: cookieJar) { action in
            XCTAssertEqual(action, RequestAuthenticator.WPNavigationActionType.reload)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.2)
    }
}
