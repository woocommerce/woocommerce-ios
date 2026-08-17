import Network
import XCTest
import class Networking.UserAgent
import struct NetworkingCore.CookieNonceAuthenticationEndpoints
@testable import WooCommerce

@MainActor
final class SiteCredentialLoginUseCaseTests: XCTestCase {

    func test_cookieJar_is_cleared_upon_login() throws {
        // Given
        let cookieJar = MockCookieJar()
        cookieJar.setWordPressComCookie(username: "lalala")
        let useCase = SiteCredentialLoginUseCase(
            siteURL: "https://test.com",
            cookieJar: cookieJar,
            session: MockURLSession()
        )
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
        let cookieJar = SiteCredentialLoginUseCase.makePrivateCookieJar()
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
        XCTAssertEqual(configuration.httpCookieAcceptPolicy, .always)
        XCTAssertEqual(configuration.protocolClasses?.isEmpty, true)
    }

    func test_make_private_cookie_jar_returns_non_shared_functional_cookie_storage() throws {
        // Given
        let cookieJar = SiteCredentialLoginUseCase.makePrivateCookieJar()
        let url = try XCTUnwrap(URL(string: "https://private-cookie-storage.test"))
        let cookie = try XCTUnwrap(HTTPCookie(properties: [
            .domain: url.host ?? "",
            .path: "/",
            .name: "private-cookie-storage-sentinel",
            .value: "present"
        ]))

        // When
        cookieJar.setCookie(cookie)

        // Then
        XCTAssertFalse(cookieJar === HTTPCookieStorage.shared)
        XCTAssertTrue(cookieJar.cookies(for: url)?.contains(cookie) == true)
        cookieJar.deleteCookie(cookie)
    }

    func test_handle_login_when_only_primary_session_is_injected_then_uses_it_for_the_entire_transaction() async throws {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let submissionURL = siteURL + "/credential-submit"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm(action: submissionURL).utf8))
        session.simulateResponse(for: submissionURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))
        let useCase = SiteCredentialLoginUseCase(
            siteURL: siteURL,
            cookieJar: MockCookieJar(),
            session: session
        )

        // When
        let result = await performLogin(using: useCase)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.compactMap(\.httpMethod), ["GET", "POST", "GET"])
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL, submissionURL, nonceURL])
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
        let secureLoginURL = "https://test.com" + SiteCredentialLoginUseCase.Constants.loginPath
        let secureNonceURL = "https://test.com" + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 302,
            headerFields: ["Location": secureLoginURL]
        )
        session.simulateResponse(for: secureLoginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(
            for: secureLoginURL,
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

    func test_handle_login_when_preflight_has_three_safe_redirects_then_nonce_request_succeeds() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let redirectURLs = (1...3).map { "\(siteURL)/login-step-\($0)" }
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": redirectURLs[0]])
        session.simulateResponse(for: redirectURLs[0], statusCode: 302, headerFields: ["Location": redirectURLs[1]])
        session.simulateResponse(for: redirectURLs[1], statusCode: 302, headerFields: ["Location": redirectURLs[2]])
        session.simulateResponse(for: redirectURLs[2], data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: redirectURLs[2], statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL] + redirectURLs + [nonceURL])
    }

    func test_handle_login_when_preflight_has_fourth_redirect_then_rejects_without_contacting_target() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let redirectURLs = (1...4).map { "\(siteURL)/login-step-\($0)" }
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": redirectURLs[0]])
        session.simulateResponse(for: redirectURLs[0], statusCode: 302, headerFields: ["Location": redirectURLs[1]])
        session.simulateResponse(for: redirectURLs[1], statusCode: 302, headerFields: ["Location": redirectURLs[2]])
        session.simulateResponse(for: redirectURLs[2], statusCode: 302, headerFields: ["Location": redirectURLs[3]])

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL] + Array(redirectURLs.prefix(3)))
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == redirectURLs[3] })
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_handle_login_when_form_action_is_same_site_then_posts_to_transaction_local_action() async throws {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let submissionURL = siteURL + "/custom-submit"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm(action: "/custom-submit").utf8))
        loginSession.simulateResponse(for: submissionURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(loginSession.lastRequest?.url?.absoluteString, submissionURL)
        let bodyData = try XCTUnwrap(loginSession.lastRequest?.httpBody)
        let body = try XCTUnwrap(String(data: bodyData, encoding: .utf8))
        XCTAssertTrue(body.contains("redirect_to=https://test.com/wp-admin/admin-ajax.php?action%3Drest-nonce"))
    }

    func test_handle_login_when_form_action_is_cross_origin_then_rejects_without_posting_credentials() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            data: Data(loginForm(action: "https://attacker.example/collect").utf8)
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_handle_login_when_preflight_requires_basic_authentication_then_returns_basic_authentication_required() async {
        // Given
        let siteURL = "https://test.com"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(
            for: siteURL + SiteCredentialLoginUseCase.Constants.loginPath,
            statusCode: 401,
            headerFields: ["WWW-Authenticate": "Basic realm=\"store\""]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .basicAuthenticationRequired)
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_handle_login_when_credentials_return_login_error_then_preserves_server_message() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        let invalidCredentialsHTML = "<div id=\"login_error\">Incorrect password</div>" + loginForm()
        loginSession.simulateResponse(for: loginURL, data: Data(invalidCredentialsHTML.utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .loginFailed(message: "Incorrect password"))
    }

    func test_handle_login_when_credentials_return_wordpress_shake_marker_then_returns_invalid_credentials() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        let invalidCredentialsHTML = "<div id=\"login_error\">Incorrect password</div>" + loginForm() +
            "<script>document.querySelector('form').classList.add('shake')</script>"
        loginSession.simulateResponse(for: loginURL, data: Data(invalidCredentialsHTML.utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidCredentials)
    }

    func test_handle_login_when_injected_endpoints_match_site_then_uses_custom_entry_and_admin_paths() async throws {
        // Given
        let siteURL = "https://test.com/shop"
        let customLoginURL = try XCTUnwrap(URL(string: "https://test.com/private-login"))
        let customAdminURL = try XCTUnwrap(URL(string: "https://test.com/private-admin/"))
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: siteURL)),
            loginEntryURL: customLoginURL,
            adminBaseURL: customAdminURL
        )
        let nonceURL = "https://test.com/private-admin/admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: customLoginURL.absoluteString, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: customLoginURL.absoluteString, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, endpoints: endpoints, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.first?.url, customLoginURL)
    }

    func test_handle_login_when_injected_endpoints_site_mismatches_initializer_then_rejects_without_request() async throws {
        // Given
        let siteURL = "https://test.com"
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: XCTUnwrap(URL(string: "https://other.example")))
        let session = MockURLSession()
        let loginSession = MockURLSession()

        // When
        let result = await performLogin(siteURL: siteURL, endpoints: endpoints, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(session.requestCount, 0)
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_handle_login_when_admin_verification_is_enabled_then_follows_safe_redirect_and_requires_dashboard() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let dashboardURL = adminURL + "index.php"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: adminURL, statusCode: 302, headerFields: ["Location": dashboardURL])
        let dashboard = "<body class=\"wp-admin index-php\"><div id=\"dashboard-widgets-wrap\"></div></body>"
        session.simulateResponse(for: dashboardURL, data: Data(dashboard.utf8))
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(
            session.receivedRequests.compactMap(\.url?.absoluteString),
            [loginURL, adminURL, dashboardURL, nonceURL]
        )
    }

    func test_handle_login_when_admin_verification_returns_login_form_then_fails_before_nonce_request() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        let loginPage = loginForm() + "<script>document.querySelector('form').classList.add('shake')</script>"
        session.simulateResponse(for: adminURL, data: Data(loginPage.utf8))

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        assertFailure(result, matches: .invalidCredentials)
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == nonceURL })
    }

    func test_handle_login_when_admin_verification_finds_dashboard_at_unexpected_path_then_rejects_it() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let unexpectedDashboardURL = siteURL + "/other-admin/"
        let nonceURL = adminURL + "admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: adminURL, statusCode: 302, headerFields: ["Location": unexpectedDashboardURL])
        let dashboard = "<body class=\"wp-admin index-php\"><div id=\"dashboard-widgets-wrap\"></div></body>"
        session.simulateResponse(for: unexpectedDashboardURL, data: Data(dashboard.utf8))

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == nonceURL })
    }

    func test_handle_login_when_endpoint_construction_fails_then_completes_asynchronously() async {
        // Given
        let session = MockURLSession()
        let loginSession = MockURLSession()
        let useCase = SiteCredentialLoginUseCase(
            siteURL: "not a valid absolute site URL",
            cookieJar: MockCookieJar(),
            session: session,
            loginSession: loginSession
        )
        let completion = expectation(description: "Login completion")
        var isLoading = true
        var receivedError: SiteCredentialLoginError?
        useCase.setupHandlers(onLoginSuccess: {
            XCTFail("Expected endpoint validation to fail")
            completion.fulfill()
        }, onLoginFailure: { error in
            receivedError = error
            isLoading = false
            completion.fulfill()
        })

        // When
        useCase.handleLogin(username: "username", password: "password")

        // Then
        XCTAssertTrue(isLoading)
        XCTAssertNil(receivedError)
        await fulfillment(of: [completion], timeout: 1)
        XCTAssertFalse(isLoading)
        assertError(receivedError, matches: .invalidLoginResponse)
        XCTAssertEqual(session.requestCount, 0)
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_handle_login_when_verified_credential_post_is_missing_then_returns_unacceptable_status_code() async {
        for statusCode in [404, 410] {
            // Given
            let siteURL = "https://test.com"
            let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
            let session = MockURLSession()
            let loginSession = MockURLSession()
            loginSession.simulateResponse(for: loginURL, statusCode: statusCode)

            // When
            let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

            // Then
            assertFailure(result, matches: .unacceptableStatusCode(code: statusCode))
        }
    }

    func test_handle_login_when_preflight_contains_malformed_or_decoy_markup_then_never_posts_credentials() async {
        for html in malformedLoginMarkup() {
            // Given
            let siteURL = "https://test.com"
            let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
            let session = MockURLSession()
            let loginSession = MockURLSession()
            session.simulateResponse(for: loginURL, data: Data(html.utf8))

            // When
            let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

            // Then
            assertFailure(result, matches: .invalidLoginResponse)
            XCTAssertEqual(loginSession.requestCount, 0, "Unexpected credential POST for markup: \(html)")
        }
    }

    func test_handle_login_when_admin_verification_has_three_safe_redirects_then_succeeds() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let redirectURLs = [adminURL + "one", adminURL + "two", adminURL + "index.php"]
        let nonceURL = adminURL + "admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: adminURL, statusCode: 302, headerFields: ["Location": redirectURLs[0]])
        session.simulateResponse(for: redirectURLs[0], statusCode: 302, headerFields: ["Location": redirectURLs[1]])
        session.simulateResponse(for: redirectURLs[1], statusCode: 302, headerFields: ["Location": redirectURLs[2]])
        session.simulateResponse(for: redirectURLs[2], data: Data(authenticatedDashboard().utf8))
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL, adminURL] + redirectURLs + [nonceURL])
    }

    func test_handle_login_when_admin_verification_has_fourth_redirect_then_never_contacts_target() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let redirectURLs = (1...4).map { adminURL + "step-\($0)" }
        let nonceURL = adminURL + "admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: adminURL, statusCode: 302, headerFields: ["Location": redirectURLs[0]])
        session.simulateResponse(for: redirectURLs[0], statusCode: 302, headerFields: ["Location": redirectURLs[1]])
        session.simulateResponse(for: redirectURLs[1], statusCode: 302, headerFields: ["Location": redirectURLs[2]])
        session.simulateResponse(for: redirectURLs[2], statusCode: 302, headerFields: ["Location": redirectURLs[3]])

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL, adminURL] + Array(redirectURLs.prefix(3)))
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == redirectURLs[3] })
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == nonceURL })
    }

    func test_handle_login_when_admin_verification_redirect_is_off_origin_then_never_contacts_destination() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let nonceURL = adminURL + "admin-ajax.php?action=rest-nonce"
        let unsafeDestination = "https://attacker.example/wp-admin/"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: adminURL, statusCode: 302, headerFields: ["Location": unsafeDestination])

        // When
        let result = await performLogin(
            siteURL: siteURL,
            verifyAdminDashboard: true,
            session: session,
            loginSession: loginSession
        )

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == unsafeDestination })
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == nonceURL })
    }

    func test_handle_login_when_retrieving_nonce_then_follow_up_is_bodyless_get() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        loginSession.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": nonceURL])
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        let nonceRequest = session.receivedRequests.last
        XCTAssertEqual(nonceRequest?.httpMethod, "GET")
        XCTAssertNil(nonceRequest?.httpBody)
        XCTAssertNil(nonceRequest?.httpBodyStream)
    }

    func test_handle_login_when_called_twice_then_each_attempt_starts_from_durable_entry() async throws {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + "/durable-entry"
        let redirectedLoginURL = siteURL + "/redirected-login"
        let submissionURL = siteURL + "/credential-submit"
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: siteURL)),
            loginEntryURL: XCTUnwrap(URL(string: loginURL))
        )
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, statusCode: 302, headerFields: ["Location": redirectedLoginURL])
        session.simulateResponse(for: redirectedLoginURL, data: Data(loginForm(action: submissionURL).utf8))
        loginSession.simulateResponse(for: submissionURL, data: Data("<div id=\"login_error\">Try again</div>".utf8))
        let useCase = SiteCredentialLoginUseCase(
            siteURL: siteURL,
            endpoints: endpoints,
            cookieJar: MockCookieJar(),
            session: session,
            loginSession: loginSession
        )

        // When
        let firstResult = await performLogin(using: useCase)
        let secondResult = await performLogin(using: useCase)

        // Then
        assertFailure(firstResult, matches: .loginFailed(message: "Try again"))
        assertFailure(secondResult, matches: .loginFailed(message: "Try again"))
        XCTAssertEqual(
            session.receivedRequests.compactMap(\.url?.absoluteString),
            [loginURL, redirectedLoginURL, loginURL, redirectedLoginURL]
        )
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [submissionURL, submissionURL])
    }

    func test_handle_login_when_transport_fails_then_preserves_generic_failure() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let transportError = URLError(.notConnectedToInternet)
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateError(for: loginURL, error: transportError)

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        guard case .failure(.genericFailure(let underlyingError)) = result else {
            return XCTFail("Expected generic transport failure, received \(result)")
        }
        XCTAssertEqual((underlyingError as NSError).domain, NSURLErrorDomain)
        XCTAssertEqual((underlyingError as NSError).code, URLError.notConnectedToInternet.rawValue)
        XCTAssertEqual(loginSession.requestCount, 0)
    }

    func test_production_url_loading_keeps_cookies_private_and_carries_them_through_dashboard_and_nonce() async throws {
        // Given
        let server = try SiteCredentialLoginLoopbackServer(scenario: .successfulDashboardLogin)
        defer { server.stop() }
        let siteURL = try server.siteURL()
        let sentinel = try XCTUnwrap(HTTPCookie(properties: [
            .domain: "shared-cookie-sentinel.invalid",
            .path: "/",
            .name: "site_credential_login_\(UUID().uuidString)",
            .value: "preserve"
        ]))
        HTTPCookieStorage.shared.setCookie(sentinel)
        defer { HTTPCookieStorage.shared.deleteCookie(sentinel) }
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL.absoluteString, verifyAdminDashboard: true)

        // When
        let result = await performLogin(using: useCase)

        // Then
        XCTAssertNoThrow(try result.get())
        let requests = server.receivedRequests
        let credentialRequest = try XCTUnwrap(requests.first { $0.method == "POST" })
        XCTAssertTrue(credentialRequest.headers["cookie"]?.contains("preflight_cookie=present") == true)
        let dashboardRequest = try XCTUnwrap(requests.first { $0.path == "/wp-admin/" })
        XCTAssertTrue(dashboardRequest.headers["cookie"]?.contains("login_cookie=present") == true)
        let nonceRequest = try XCTUnwrap(requests.first { $0.path == "/wp-admin/admin-ajax.php?action=rest-nonce" })
        XCTAssertEqual(nonceRequest.method, "GET")
        XCTAssertTrue(nonceRequest.body.isEmpty)
        XCTAssertTrue(nonceRequest.headers["cookie"]?.contains("login_cookie=present") == true)
        let sharedCookies = HTTPCookieStorage.shared.cookies ?? []
        XCTAssertTrue(sharedCookies.contains { $0.name == sentinel.name })
        XCTAssertFalse(sharedCookies.contains { cookie in
            cookie.domain == "127.0.0.1" && ["preflight_cookie", "login_cookie"].contains(cookie.name)
        })
    }

    func test_production_url_loading_when_preflight_requires_basic_authentication_then_returns_basic_authentication_required() async throws {
        // Given
        let server = try SiteCredentialLoginLoopbackServer(scenario: .basicAuthenticationRequired)
        defer { server.stop() }
        let useCase = SiteCredentialLoginUseCase(siteURL: try server.siteURL().absoluteString)

        // When
        let result = await performLogin(using: useCase)

        // Then
        assertFailure(result, matches: .basicAuthenticationRequired)
        let requests = server.receivedRequests
        XCTAssertFalse(requests.isEmpty)
        XCTAssertTrue(requests.allSatisfy { $0.method == "GET" })
        XCTAssertTrue(requests.allSatisfy { $0.path == "/wp-login.php" })
        XCTAssertTrue(requests.allSatisfy { $0.headers["authorization"] == nil })
        XCTAssertFalse(requests.contains { $0.method == "POST" })
    }

    func test_production_url_loading_blocks_body_preserving_non_exact_credential_redirect_target() async throws {
        // Given
        let server = try SiteCredentialLoginLoopbackServer(scenario: .bodyPreservingCredentialRedirect)
        defer { server.stop() }
        let siteURL = try server.siteURL()
        let useCase = SiteCredentialLoginUseCase(siteURL: siteURL.absoluteString)

        // When
        let result = await performLogin(using: useCase)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        let credentialRequest = try XCTUnwrap(server.receivedRequests.first { $0.method == "POST" })
        XCTAssertFalse(credentialRequest.body.isEmpty)
        XCTAssertFalse(server.receivedRequests.contains { $0.path == "/body-preserving-target" })
    }

    func test_handle_login_when_credential_redirect_is_exact_admin_base_then_fetches_exact_nonce_without_requesting_redirect_target() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let adminURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + "/"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL)
        loginSession.simulateResponse(
            for: loginURL,
            statusCode: 302,
            headerFields: ["Location": adminURL]
        )
        session.simulateResponse(for: nonceURL, data: Data("validnonce".utf8))

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.httpMethod), ["POST"])
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL, nonceURL])
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == adminURL })
        XCTAssertEqual(session.receivedRequests.last?.httpMethod, "GET")
        XCTAssertNil(session.receivedRequests.last?.httpBody)
        XCTAssertNil(session.receivedRequests.last?.httpBodyStream)
    }

    func test_handle_login_when_credential_redirect_is_custom_nonce_then_fetches_configured_nonce_and_returns_admin_not_found() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let redirectedNonceURL = siteURL + "/hidden-admin/admin-ajax.php?action=rest-nonce"
        let configuredNonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath +
            SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
        loginSession.simulateResponse(
            for: loginURL,
            statusCode: 302,
            headerFields: ["Location": redirectedNonceURL]
        )
        session.simulateResponse(for: configuredNonceURL, statusCode: 404)

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .inaccessibleAdminPage)
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL, configuredNonceURL])
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == redirectedNonceURL })
        XCTAssertEqual(session.receivedRequests.last?.httpMethod, "GET")
        XCTAssertNil(session.receivedRequests.last?.httpBody)
        XCTAssertNil(session.receivedRequests.last?.httpBodyStream)
    }

    func test_handle_login_when_credential_redirect_is_unrelated_same_site_admin_then_rejects_without_requesting_target_or_nonce() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let unrelatedAdminURL = siteURL + "/other-admin/"
        let nonceURL = siteURL + SiteCredentialLoginUseCase.Constants.adminPath + SiteCredentialLoginUseCase.Constants.wporgNoncePath
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL)
        loginSession.simulateResponse(
            for: loginURL,
            statusCode: 302,
            headerFields: ["Location": unrelatedAdminURL]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.httpMethod), ["POST"])
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == unrelatedAdminURL })
        XCTAssertFalse(session.receivedRequests.contains { $0.url?.absoluteString == nonceURL })
    }

    func test_handleLogin_when_loginRedirectLocation_is_crossOriginRestNonce_then_returns_invalidLoginResponse() async {
        // Given
        let siteURL = "https://test.com"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let unsafeNonceURL = "https://example-attacker.test/wp-admin/admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL)
        loginSession.simulateResponse(
            for: loginURL,
            statusCode: 302,
            headerFields: ["Location": unsafeNonceURL]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
    }

    func test_handleLogin_when_loginRedirectLocation_is_sameHostDifferentPortRestNonce_then_returns_invalidLoginResponse() async {
        // Given
        let siteURL = "https://test.com:8080"
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        let unsafeNonceURL = "https://test.com:9090/wp-admin/admin-ajax.php?action=rest-nonce"
        let session = MockURLSession()
        let loginSession = MockURLSession()
        session.simulateResponse(for: loginURL)
        loginSession.simulateResponse(
            for: loginURL,
            statusCode: 302,
            headerFields: ["Location": unsafeNonceURL]
        )

        // When
        let result = await performLogin(siteURL: siteURL, session: session, loginSession: loginSession)

        // Then
        assertFailure(result, matches: .invalidLoginResponse)
        XCTAssertEqual(session.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
        XCTAssertEqual(loginSession.receivedRequests.compactMap(\.url?.absoluteString), [loginURL])
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

private final class SiteCredentialLoginLoopbackServer: @unchecked Sendable {
    enum Scenario: Equatable {
        case successfulDashboardLogin
        case bodyPreservingCredentialRedirect
        case basicAuthenticationRequired
    }

    struct Request: Sendable {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data
    }

    private struct Response {
        let status: String
        let headers: [String: String]
        let body: Data
    }

    enum ServerError: Error {
        case failedToStart
        case missingPort
    }

    private let scenario: Scenario
    private let listener: NWListener
    private let queue = DispatchQueue(label: "com.woocommerce.site-credential-login-test-server")
    private let readiness = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var didResolveReadiness = false
    private var startupError: NWError?
    private var requests = [Request]()

    init(scenario: Scenario) throws {
        self.scenario = scenario
        self.listener = try NWListener(using: .tcp, on: .any)
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.resolveReadiness()
            case .failed(let error):
                self?.resolveReadiness(error: error)
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)

        guard readiness.wait(timeout: .now() + 5) == .success else {
            listener.cancel()
            throw ServerError.failedToStart
        }
        if startupError != nil {
            listener.cancel()
            throw ServerError.failedToStart
        }
    }

    var receivedRequests: [Request] {
        lock.withLock { requests }
    }

    func siteURL() throws -> URL {
        guard let port = listener.port?.rawValue,
              let url = URL(string: "http://127.0.0.1:\(port)") else {
            throw ServerError.missingPort
        }
        return url
    }

    func stop() {
        listener.stateUpdateHandler = nil
        listener.newConnectionHandler = nil
        listener.cancel()
        queue.sync {}
    }
}

private extension SiteCredentialLoginLoopbackServer {
    func resolveReadiness(error: NWError? = nil) {
        let shouldSignal = lock.withLock { () -> Bool in
            guard didResolveReadiness == false else {
                return false
            }
            didResolveReadiness = true
            startupError = error
            return true
        }
        if shouldSignal {
            readiness.signal()
        }
    }

    func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, accumulatedData: Data())
    }

    func receive(on connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1_024) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            var accumulatedData = accumulatedData
            if let data {
                accumulatedData.append(data)
            }
            if let requestLength = Self.requestLength(in: accumulatedData), accumulatedData.count >= requestLength {
                guard let request = Self.parseRequest(from: accumulatedData, length: requestLength) else {
                    connection.cancel()
                    return
                }
                lock.withLock {
                    self.requests.append(request)
                }
                send(response(for: request), on: connection)
            } else if error != nil || isComplete {
                connection.cancel()
            } else {
                receive(on: connection, accumulatedData: accumulatedData)
            }
        }
    }

    private func response(for request: Request) -> Response {
        switch (request.method, request.path) {
        case ("GET", "/wp-login.php") where scenario == .basicAuthenticationRequired:
            return Response(
                status: "401 Unauthorized",
                headers: ["WWW-Authenticate": "Basic realm=\"site-credential-login-sentinel\""],
                body: Data()
            )
        case ("GET", "/wp-login.php"):
            return Response(
                status: "200 OK",
                headers: ["Content-Type": "text/html", "Set-Cookie": "preflight_cookie=present; Path=/"],
                body: Data(Self.loginForm.utf8)
            )
        case ("POST", "/credential-submit") where scenario == .successfulDashboardLogin:
            return Response(
                status: "302 Found",
                headers: [
                    "Location": "/wp-admin/admin-ajax.php?action=rest-nonce",
                    "Set-Cookie": "login_cookie=present; Path=/"
                ],
                body: Data()
            )
        case ("POST", "/credential-submit"):
            return Response(
                status: "307 Temporary Redirect",
                headers: ["Location": "/body-preserving-target"],
                body: Data()
            )
        case ("GET", "/wp-admin/"):
            return Response(status: "200 OK", headers: ["Content-Type": "text/html"], body: Data(Self.dashboard.utf8))
        case ("GET", "/wp-admin/admin-ajax.php?action=rest-nonce"):
            return Response(status: "200 OK", headers: [:], body: Data("validnonce".utf8))
        default:
            return Response(status: "404 Not Found", headers: [:], body: Data())
        }
    }

    private func send(_ response: Response, on connection: NWConnection) {
        var headers = response.headers
        headers["Content-Length"] = String(response.body.count)
        headers["Connection"] = "close"
        let headerLines = headers.map { "\($0.key): \($0.value)" }.joined(separator: "\r\n")
        var data = Data("HTTP/1.1 \(response.status)\r\n\(headerLines)\r\n\r\n".utf8)
        data.append(response.body)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    static func requestLength(in data: Data) -> Int? {
        let separator = Data("\r\n\r\n".utf8)
        guard let separatorRange = data.range(of: separator),
              let headers = String(data: data[..<separatorRange.lowerBound], encoding: .utf8) else {
            return nil
        }
        let contentLength = headers.components(separatedBy: "\r\n")
            .first { $0.lowercased().hasPrefix("content-length:") }
            .flatMap { Int($0.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) } ?? 0
        return separatorRange.upperBound + contentLength
    }

    static func parseRequest(from data: Data, length: Int) -> Request? {
        let separator = Data("\r\n\r\n".utf8)
        guard let separatorRange = data.range(of: separator),
              let headerText = String(data: data[..<separatorRange.lowerBound], encoding: .utf8) else {
            return nil
        }
        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }
        let requestParts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard requestParts.count >= 2 else {
            return nil
        }
        let headers = lines.dropFirst().reduce(into: [String: String]()) { result, line in
            guard let separatorIndex = line.firstIndex(of: ":") else {
                return
            }
            let name = line[..<separatorIndex].lowercased()
            let value = line[line.index(after: separatorIndex)...].trimmingCharacters(in: .whitespaces)
            result[name] = value
        }
        let body = data.subdata(in: separatorRange.upperBound..<length)
        return Request(method: requestParts[0], path: requestParts[1], headers: headers, body: body)
    }

    static let loginForm = """
        <form id="loginform" name="loginform" method="post" action="/credential-submit">
        <input name="log" id="user_login" type="text">
        <input name="pwd" id="user_pass" type="password">
        </form>
        """

    static let dashboard = "<body class=\"wp-admin index-php\"><div id=\"dashboard-widgets-wrap\"></div></body>"
}

// MARK: - Helpers
private extension SiteCredentialLoginUseCaseTests {
    func performLogin(siteURL: String,
                      endpoints: CookieNonceAuthenticationEndpoints? = nil,
                      verifyAdminDashboard: Bool = false,
                      session: MockURLSession,
                      loginSession: MockURLSession) async -> Result<Void, SiteCredentialLoginError> {
        if endpoints == nil {
            configureDefaultLoginForm(siteURL: siteURL, session: session)
        }
        let useCase = SiteCredentialLoginUseCase(
            siteURL: siteURL,
            endpoints: endpoints,
            verifyAdminDashboard: verifyAdminDashboard,
            cookieJar: MockCookieJar(),
            session: session,
            loginSession: loginSession
        )

        return await performLogin(using: useCase)
    }

    func performLogin(using useCase: SiteCredentialLoginUseCase) async -> Result<Void, SiteCredentialLoginError> {
        return await withCheckedContinuation { continuation in
            useCase.setupHandlers(onLoginSuccess: {
                continuation.resume(returning: .success(()))
            }, onLoginFailure: { error in
                continuation.resume(returning: .failure(error))
            })

            useCase.handleLogin(username: "test", password: "secret")
        }
    }

    func configureDefaultLoginForm(siteURL: String, session: MockURLSession) {
        let loginURL = siteURL + SiteCredentialLoginUseCase.Constants.loginPath
        if let configured = session.responses[loginURL],
           let response = configured.1 as? HTTPURLResponse,
           response.statusCode != 200 || configured.0.isEmpty == false {
            return
        }
        session.simulateResponse(for: loginURL, data: Data(loginForm().utf8))
    }

    func loginForm(action: String? = nil) -> String {
        let action = action.map { " action=\"\($0)\"" } ?? ""
        return "<form id=\"loginform\" name=\"loginform\" method=\"post\"\(action)>" +
            "<input name=\"log\" id=\"user_login\" type=\"text\">" +
            "<input name=\"pwd\" id=\"user_pass\" type=\"password\"></form>"
    }

    func malformedLoginMarkup() -> [String] {
        let form = loginForm()
        return [
            form.replacingOccurrences(of: " name=\"loginform\"", with: ""),
            form.replacingOccurrences(of: "method=\"post\"", with: "method=\"get\""),
            form.replacingOccurrences(of: "type=\"password\"", with: "type=\"hidden\""),
            form + form,
            "<script>\(form)</script>"
        ]
    }

    func authenticatedDashboard() -> String {
        "<body class=\"wp-admin index-php\"><div id=\"dashboard-widgets-wrap\"></div></body>"
    }

    func assertError(_ actualError: SiteCredentialLoginError?,
                     matches expectedError: SiteCredentialLoginError,
                     file: StaticString = #filePath,
                     line: UInt = #line) {
        guard let actualError else {
            return XCTFail("Expected an error", file: file, line: line)
        }
        assertFailure(.failure(actualError), matches: expectedError, file: file, line: line)
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
             (.inaccessibleAdminPage, .inaccessibleAdminPage),
             (.inaccessibleLoginPage, .inaccessibleLoginPage),
             (.basicAuthenticationRequired, .basicAuthenticationRequired),
             (.invalidCredentials, .invalidCredentials):
            break
        case let (.unacceptableStatusCode(actualCode), .unacceptableStatusCode(expectedCode)):
            XCTAssertEqual(actualCode, expectedCode, file: file, line: line)
        case let (.loginFailed(actualMessage), .loginFailed(expectedMessage)):
            XCTAssertEqual(actualMessage, expectedMessage, file: file, line: line)
        default:
            XCTFail("Unexpected error: \(actualError)", file: file, line: line)
        }
    }
}
