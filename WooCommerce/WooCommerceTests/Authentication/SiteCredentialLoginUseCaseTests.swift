import XCTest
import class Networking.UserAgent
@testable import WooCommerce

final class SiteCredentialLoginUseCaseTests: XCTestCase {

    func test_cookieJar_is_cleared_upon_login() throws {
        // Given
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: "lalala")
        let useCase = SiteCredentialLoginUseCase(siteURL: "https://test.com", cookieJar: cookieJar)
        // confidence check
        let cookies = try XCTUnwrap(cookieJar.cookies)
        XCTAssertTrue(cookies.isNotEmpty)

        // When
        useCase.handleLogin(username: "test", password: "secret")

        // Then
        XCTAssertEqual(cookieJar.cookies?.isEmpty, true)
    }

    func test_sessionConfiguration_when_customURLProtocolIsPresent_then_removesProtocolClasses() {
        // Given
        let cookieJar = MockCookieJar()
        let baseConfiguration = URLSessionConfiguration.default
        baseConfiguration.protocolClasses = [SiteCredentialLoginTestURLProtocol.self]

        // When
        let configuration = SiteCredentialLoginUseCase.makeSessionConfiguration(
            cookieJar: cookieJar,
            baseConfiguration: baseConfiguration
        )

        // Then
        XCTAssertTrue(configuration.httpCookieStorage === cookieJar)
        XCTAssertEqual(configuration.httpShouldSetCookies, true)
        XCTAssertEqual(configuration.protocolClasses?.isEmpty, true)
    }

    func test_handleLogin_when_loginRedirectLocation_is_absoluteSameOrigin_then_nonceRequestSucceeds() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath]
        )
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath,
            data: Data("validnonce".utf8)
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(loginSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(session.requestCount, 2)
        XCTAssertEqual(
            session.receivedRequests.last?.url?.absoluteString,
            siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        )
    }

    func test_handleLogin_when_loginRedirectLocation_is_relative_then_resolves_and_sets_userAgent_headers() async throws {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath]
        )
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath,
            data: Data("validnonce".utf8)
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.first?.value(forHTTPHeaderField: "User-Agent"), UserAgent.defaultUserAgent)
        XCTAssertEqual(loginSession.lastRequest?.value(forHTTPHeaderField: "User-Agent"), UserAgent.defaultUserAgent)
        XCTAssertEqual(
            session.receivedRequests.last?.value(forHTTPHeaderField: "User-Agent"),
            UserAgent.defaultUserAgent
        )
    }

    func test_handleLogin_when_loginRedirectLocation_is_subdirectoryRestNonce_then_nonceRequestSucceeds() async {
        // Given
        let siteURL = "https://test.com/blog"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": nonceURL]
        )
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.last?.url?.absoluteString, nonceURL)
    }

    func test_handleLogin_when_loginRedirectLocation_is_httpsUpgrade_then_nonceRequestSucceeds() async {
        // Given
        let siteURL = "http://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        let secureNonceURL = "https://test.com" + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": secureNonceURL]
        )
        session.simulateResponse(for: secureNonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.last?.url?.absoluteString, secureNonceURL)
    }

    func test_handleLogin_when_loginRedirectLocation_is_not_restNonce_then_returns_invalidLoginResponse() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": siteURL + SiteCredentialLoginUseCase.Constants.adminPath]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
    }

    func test_handleLogin_when_loginRedirectLocation_is_crossOriginRestNonce_then_returns_invalidLoginResponse() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": "https://example-attacker.test/wp-admin/admin-ajax.php?action=rest-nonce"]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
    }

    func test_handleLogin_when_loginRedirectLocation_is_sameHostDifferentPortRestNonce_then_returns_invalidLoginResponse() async {
        // Given
        let siteURL = "https://test.com:8080"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": "https://test.com:9090/wp-admin/admin-ajax.php?action=rest-nonce"]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
    }

    func test_handleLogin_when_manualNonceRequest_returns_notFound_then_returns_inaccessibleAdminPage() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath]
        )
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath,
            statusCode: 404
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .inaccessibleAdminPage)
    }

    func test_handleLogin_when_manualNonceRequest_returns_rateLimited_then_returns_unacceptableStatusCode() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath)
        loginSession.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath]
        )
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath,
            statusCode: 429
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .unacceptableStatusCode(code: 429))
    }

    func test_basicAuthenticationChallenge_is_detected_from_response_headers() throws {
        // Given
        let response = try XCTUnwrap(makeHTTPURLResponse(
            statusCode: 401,
            headers: ["WWW-Authenticate": "Basic realm=\"Restricted Area\""]
        ))

        // Then
        XCTAssertTrue(response.containsHTTPBasicAuthenticationChallenge)
    }

    func test_basicAuthenticationChallenge_returns_false_when_header_is_missing() throws {
        // Given
        let response = try XCTUnwrap(makeHTTPURLResponse(
            statusCode: 401,
            headers: ["Content-Type": "text/html"]
        ))

        // Then
        XCTAssertFalse(response.containsHTTPBasicAuthenticationChallenge)
    }
}

private final class SiteCredentialLoginTestURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {}

    override func stopLoading() {}
}

// MARK: - Helpers
private extension SiteCredentialLoginUseCaseTests {
    func performLogin(siteURL: String,
                      session: MockURLSession,
                      loginSession: MockURLSession) async -> Result<Void, SiteCredentialLoginError> {
        let useCase = SiteCredentialLoginUseCase(
            siteURL: siteURL,
            cookieJar: MockCookieJar(),
            session: session,
            loginSession: loginSession
        )

        return await withCheckedContinuation { continuation in
            useCase.setupHandlers(onLoginSuccess: {
                continuation.resume(returning: .success(()))
            }, onLoginFailure: { error in
                continuation.resume(returning: .failure(error))
            })

            useCase.handleLogin(username: "test", password: "secret")
        }
    }

    func makeHTTPURLResponse(statusCode: Int, headers: [String: String]) -> HTTPURLResponse? {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )
    }

    func assertFailure(_ result: Result<Void, SiteCredentialLoginError>,
                       matches expectedError: SiteCredentialLoginError,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        guard case .failure(let actualError) = result else {
            XCTFail("Expected failure result", file: file, line: line)
            return
        }

        switch (actualError, expectedError) {
        case (.invalidLoginResponse, .invalidLoginResponse),
             (.inaccessibleAdminPage, .inaccessibleAdminPage):
            break
        case let (.unacceptableStatusCode(actualCode), .unacceptableStatusCode(expectedCode)):
            XCTAssertEqual(actualCode, expectedCode, file: file, line: line)
        default:
            XCTFail("Unexpected error: \(actualError)", file: file, line: line)
        }
    }
}
