import Alamofire
import Network
import XCTest
@testable import Networking
@testable import NetworkingCore

@MainActor
final class CookieNonceAuthenticatorTests: XCTestCase {

    private let loginURL = URL(string: "https://example.com/wp-login.php")!
    private let adminURL = URL(string: "https://example.com/wp-admin/")!
    private let siteURL = URL(string: "https://example.com")!
    private let apiRequest = URLRequest(url: URL(string: "https://example.com/wp-json/")!)
    private let sampleUser = "user123"
    private let samplePassword = "password *+/$&=2+é"

    override func tearDown() {
        CookieNonceAuthenticationURLProtocol.reset()
        super.tearDown()
    }

    func test_authentication_session_configuration_when_source_has_protocol_classes_then_clears_them_and_preserves_cookie_storage() {
        // Given
        let sourceConfiguration = URLSessionConfiguration.ephemeral
        let cookieStorage = HTTPCookieStorage()
        sourceConfiguration.timeoutIntervalForRequest = 17
        sourceConfiguration.protocolClasses = [CookieNonceAuthenticationURLProtocol.self]
        sourceConfiguration.httpCookieStorage = cookieStorage
        let sourceSession = Session(configuration: sourceConfiguration)

        // When
        let configuration = CookieNonceAuthenticator.authenticationSessionConfiguration(from: sourceSession)

        // Then
        XCTAssertTrue(configuration.protocolClasses?.isEmpty == true)
        XCTAssertTrue(configuration.httpCookieStorage === cookieStorage)
        XCTAssertEqual(configuration.timeoutIntervalForRequest, 17)
        XCTAssertEqual(
            sourceSession.sessionConfiguration.protocolClasses?.map { ObjectIdentifier($0) },
            [ObjectIdentifier(CookieNonceAuthenticationURLProtocol.self)]
        )
    }

    func test_cookie_nonce_authenticator_encode_parameters_correctly() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: loginURL,
            adminBaseURL: adminURL
        )
        let config = CookieNonceAuthenticatorConfiguration(username: sampleUser,
                                                           password: samplePassword,
                                                           endpoints: endpoints)
        let authenticator = CookieNonceAuthenticator(configuration: config)


        let nonceURL = try endpoints.nonceURL()
        let generatedBodyAsData = try XCTUnwrap(
            authenticator.authenticatedRequest(submissionURL: loginURL, nonceURL: nonceURL).httpBody
        )
        let generatedBodyAsString = try XCTUnwrap(String(data: generatedBodyAsData, encoding: .utf8))
        let generatedBodyParameters = generatedBodyAsString.split(separator: Character("&"))

        // When
        /// Expected parameters with encoded data
        ///
        let expectedParameters = [
            "log": "user123",
            "pwd": "password%20*%2B/$%26%3D2%2B%C3%A9",
            "rememberme": "true",
            "redirect_to": "https://example.com/wp-admin/admin-ajax.php?action%3Drest-nonce"
        ]

        // Then
        /// Note: As of iOS 12 the parameters were being serialized at random positions. That's *why* this test is a bit extra complex!
        ///
        for parameter in generatedBodyParameters {
            let components = parameter.split(separator: Character("="))
            let key = String(components[0])
            let value = String(components[1])

            XCTAssertEqual(value, expectedParameters[key])
        }
    }

    func test_authenticated_request_when_form_action_differs_then_posts_transaction_locally() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: loginURL,
            adminBaseURL: adminURL
        )
        let config = CookieNonceAuthenticatorConfiguration(
            username: sampleUser,
            password: samplePassword,
            endpoints: endpoints
        )
        let authenticator = CookieNonceAuthenticator(configuration: config)
        let formAction = try XCTUnwrap(URL(string: "https://example.com/custom-login-handler"))

        // When
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        let request = try authenticator.authenticatedRequest(submissionURL: formAction, nonceURL: nonceURL)

        // Then
        XCTAssertEqual(request.url, formAction)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
    }

    func test_authenticate_when_form_action_differs_then_posts_credentials_and_gets_exact_nonce() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let submissionURL = try XCTUnwrap(URL(string: "https://example.com/custom-submit"))
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(loginForm(action: "/custom-submit").utf8)
        )
        CookieNonceAuthenticationURLProtocol.stub(
            method: "POST",
            url: submissionURL,
            statusCode: 302,
            headers: ["Location": nonceURL.absoluteString]
        )
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: nonceURL, data: Data("freshnonce".utf8))

        // When
        let nonce = try await authenticator.authenticate(session: makeSession())

        // Then
        XCTAssertEqual(nonce, "freshnonce")
        let requests = CookieNonceAuthenticationURLProtocol.receivedRequests
        XCTAssertEqual(requests.compactMap(\.httpMethod), ["GET", "POST", "GET"])
        XCTAssertEqual(requests.compactMap(\.url), [loginURL, submissionURL, nonceURL])
        let bodyData = try XCTUnwrap(requests[1].httpBody)
        let body = try XCTUnwrap(String(data: bodyData, encoding: .utf8))
        XCTAssertTrue(body.contains("redirect_to=https://example.com/wp-admin/admin-ajax.php?action%3Drest-nonce"))
    }

    func test_authenticate_when_credential_redirect_is_exact_admin_base_then_gets_exact_nonce_without_requesting_redirect_target() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let submissionURL = try XCTUnwrap(URL(string: "https://example.com/custom-submit"))
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(loginForm(action: submissionURL.absoluteString).utf8)
        )
        CookieNonceAuthenticationURLProtocol.stub(
            method: "POST",
            url: submissionURL,
            statusCode: 302,
            headers: ["Location": adminURL.absoluteString]
        )
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: nonceURL, data: Data("freshnonce".utf8))

        // When
        let nonce = try await authenticator.authenticate(session: makeSession())

        // Then
        XCTAssertEqual(nonce, "freshnonce")
        let requests = CookieNonceAuthenticationURLProtocol.receivedRequests
        XCTAssertEqual(requests.compactMap(\.httpMethod), ["GET", "POST", "GET"])
        XCTAssertEqual(requests.compactMap(\.url), [loginURL, submissionURL, nonceURL])
        XCTAssertEqual(requests.filter { $0.httpMethod == "POST" }.count, 1)
        XCTAssertFalse(requests.contains { $0.url == adminURL })
        XCTAssertNil(requests.last?.httpBody)
        XCTAssertNil(requests.last?.httpBodyStream)
    }

    func test_authenticate_when_credential_redirect_is_custom_nonce_then_gets_configured_nonce_and_reports_admin_not_found() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let submissionURL = try XCTUnwrap(URL(string: "https://example.com/custom-submit"))
        let redirectedNonceURL = try XCTUnwrap(URL(string: "https://example.com/hidden-admin/admin-ajax.php?action=rest-nonce"))
        let configuredNonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(loginForm(action: submissionURL.absoluteString).utf8)
        )
        CookieNonceAuthenticationURLProtocol.stub(
            method: "POST",
            url: submissionURL,
            statusCode: 302,
            headers: ["Location": redirectedNonceURL.absoluteString]
        )
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: configuredNonceURL, statusCode: 404)

        // When / Then
        do {
            _ = try await authenticator.authenticate(session: makeSession())
            XCTFail("Expected the configured nonce endpoint to report admin not found")
        } catch CookieNonceAuthenticator.Error.authenticationFailed(.inaccessibleAdminPage) {
            let requests = CookieNonceAuthenticationURLProtocol.receivedRequests
            XCTAssertEqual(requests.compactMap(\.httpMethod), ["GET", "POST", "GET"])
            XCTAssertEqual(requests.compactMap(\.url), [loginURL, submissionURL, configuredNonceURL])
            XCTAssertFalse(requests.contains { $0.url == redirectedNonceURL })
            XCTAssertEqual(requests.last?.httpMethod, "GET")
            XCTAssertNil(requests.last?.httpBody)
            XCTAssertNil(requests.last?.httpBodyStream)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_authenticate_when_credential_redirect_is_unrelated_same_site_admin_then_rejects_without_requesting_target_or_nonce() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let submissionURL = try XCTUnwrap(URL(string: "https://example.com/custom-submit"))
        let unrelatedAdminURL = try XCTUnwrap(URL(string: "https://example.com/other-admin/"))
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(loginForm(action: submissionURL.absoluteString).utf8)
        )
        CookieNonceAuthenticationURLProtocol.stub(
            method: "POST",
            url: submissionURL,
            statusCode: 302,
            headers: ["Location": unrelatedAdminURL.absoluteString]
        )

        // When / Then
        do {
            _ = try await authenticator.authenticate(session: makeSession())
            XCTFail("Expected an unrelated same-site admin redirect to be rejected")
        } catch CookieNonceAuthenticator.Error.authenticationFailed(.invalidResponse) {
            let requests = CookieNonceAuthenticationURLProtocol.receivedRequests
            XCTAssertEqual(requests.compactMap(\.httpMethod), ["GET", "POST"])
            XCTAssertEqual(requests.compactMap(\.url), [loginURL, submissionURL])
            XCTAssertEqual(requests.filter { $0.httpMethod == "POST" }.count, 1)
            XCTAssertFalse(requests.contains { $0.url == unrelatedAdminURL })
            XCTAssertFalse(requests.contains { $0.url == nonceURL })
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_authenticate_when_preflight_is_authenticated_dashboard_then_skips_credentials_and_gets_fresh_nonce() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce"))
        let dashboard = "<body class=\"wp-core-ui index-php wp-admin\"><div id=\"dashboard-widgets-wrap\"></div></body>"
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(dashboard.utf8)
        )
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: nonceURL, data: Data("freshnonce".utf8))

        // When
        let nonce = try await authenticator.authenticate(session: makeSession())

        // Then
        XCTAssertEqual(nonce, "freshnonce")
        let requests = CookieNonceAuthenticationURLProtocol.receivedRequests
        XCTAssertEqual(requests.compactMap(\.httpMethod), ["GET", "GET"])
        XCTAssertEqual(requests.compactMap(\.url), [loginURL, nonceURL])
    }

    func test_authenticate_when_preflight_has_fourth_redirect_then_rejects_without_contacting_target() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let redirectURLs = try (1...4).map { index in
            try XCTUnwrap(URL(string: "https://example.com/login-step-\(index)"))
        }
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            statusCode: 302,
            headers: ["Location": redirectURLs[0].absoluteString]
        )
        for index in 0..<3 {
            CookieNonceAuthenticationURLProtocol.stub(
                method: "GET",
                url: redirectURLs[index],
                statusCode: 302,
                headers: ["Location": redirectURLs[index + 1].absoluteString]
            )
        }

        // When
        do {
            _ = try await authenticator.authenticate(session: makeSession())
            XCTFail("Expected the fourth redirect to be rejected")
        } catch CookieNonceAuthenticator.Error.authenticationFailed(.invalidResponse) {
            // Then
            XCTAssertEqual(
                CookieNonceAuthenticationURLProtocol.receivedRequests.compactMap(\.url),
                [loginURL] + Array(redirectURLs.prefix(3))
            )
            XCTAssertFalse(CookieNonceAuthenticationURLProtocol.receivedRequests.contains { $0.url == redirectURLs[3] })
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_authenticate_when_form_action_is_cross_origin_then_rejects_without_contacting_target() async throws {
        // Given
        let authenticator = try stubbedAuthenticator()
        let targetURL = try XCTUnwrap(URL(string: "https://attacker.example/collect"))
        CookieNonceAuthenticationURLProtocol.stub(
            method: "GET",
            url: loginURL,
            data: Data(loginForm(action: targetURL.absoluteString).utf8)
        )

        // When / Then
        do {
            _ = try await authenticator.authenticate(session: makeSession())
            XCTFail("Expected a cross-origin form action to be rejected")
        } catch CookieNonceAuthenticator.Error.authenticationFailed(.invalidResponse) {
            XCTAssertEqual(CookieNonceAuthenticationURLProtocol.receivedRequests.compactMap(\.url), [loginURL])
            XCTAssertFalse(CookieNonceAuthenticationURLProtocol.receivedRequests.contains { $0.url == targetURL })
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_authenticate_when_preflight_has_exactly_three_redirects_then_completes_custom_entry_and_admin_trace() async throws {
        // Given
        let customEntryURL = try XCTUnwrap(URL(string: "https://example.com/custom-entry"))
        let customAdminURL = try XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: customEntryURL,
            adminBaseURL: customAdminURL
        )
        let authenticator = try stubbedAuthenticator(
            configuration: CookieNonceAuthenticatorConfiguration(
                username: sampleUser,
                password: samplePassword,
                endpoints: endpoints
            )
        )
        let redirectURLs = try (1...3).map { index in
            try XCTUnwrap(URL(string: "https://example.com/entry-step-\(index)"))
        }
        let submissionURL = try XCTUnwrap(URL(string: "https://example.com/custom-submit"))
        let nonceURL = try XCTUnwrap(URL(string: "https://example.com/private-admin/admin-ajax.php?action=rest-nonce"))
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: customEntryURL, statusCode: 302, headers: ["Location": redirectURLs[0].absoluteString])
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: redirectURLs[0], statusCode: 302, headers: ["Location": redirectURLs[1].absoluteString])
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: redirectURLs[1], statusCode: 302, headers: ["Location": redirectURLs[2].absoluteString])
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: redirectURLs[2], data: Data(loginForm(action: submissionURL.absoluteString).utf8))
        CookieNonceAuthenticationURLProtocol.stub(method: "POST", url: submissionURL, statusCode: 302, headers: ["Location": nonceURL.absoluteString])
        CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: nonceURL, data: Data("freshnonce".utf8))

        // When
        let nonce = try await authenticator.authenticate(session: makeSession())

        // Then
        XCTAssertEqual(nonce, "freshnonce")
        XCTAssertEqual(
            CookieNonceAuthenticationURLProtocol.receivedRequests.compactMap(\.url),
            [customEntryURL] + redirectURLs + [submissionURL, nonceURL]
        )
    }

    func test_authenticate_when_credential_response_is_404_or_410_then_reports_unacceptable_status() async throws {
        for statusCode in [404, 410] {
            // Given
            CookieNonceAuthenticationURLProtocol.reset()
            let authenticator = try stubbedAuthenticator()
            CookieNonceAuthenticationURLProtocol.stub(method: "GET", url: loginURL, data: Data(loginForm(action: "/wp-login.php").utf8))
            CookieNonceAuthenticationURLProtocol.stub(method: "POST", url: loginURL, statusCode: statusCode)

            // When / Then
            do {
                _ = try await authenticator.authenticate(session: makeSession())
                XCTFail("Expected status \(statusCode) to fail")
            } catch CookieNonceAuthenticator.Error.authenticationFailed(.unacceptableStatusCode(let actualStatusCode)) {
                XCTAssertEqual(actualStatusCode, statusCode)
            } catch {
                XCTFail("Unexpected error for status \(statusCode): \(error)")
            }
        }
    }

    func test_offline_error_recognizes_alamofire_session_task_wrapper() {
        // Given
        let error = AFError.sessionTaskFailed(error: URLError(.notConnectedToInternet))

        // Then
        XCTAssertTrue(CookieNonceAuthenticator.isOfflineError(error))
        XCTAssertFalse(CookieNonceAuthenticator.isOfflineError(AFError.sessionTaskFailed(error: URLError(.timedOut))))
    }

    func test_wordpress_org_network_when_protected_request_is_unauthorized_then_authenticates_and_retries_with_nonce_and_cookies() async throws {
        // Given
        let scenario = CookieNonceLoopbackScenario(requiredInitialProtectedRequests: 1)
        let server = try CookieNonceLoopbackServer(handler: scenario.response)
        defer { server.stop() }
        let siteURL = server.siteURL
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: siteURL.appendingPathComponent("custom-entry"),
            adminBaseURL: siteURL.appendingPathComponent("private-admin", isDirectory: true)
        )
        let network = WordPressOrgNetwork(
            configuration: CookieNonceAuthenticatorConfiguration(
                username: sampleUser,
                password: samplePassword,
                endpoints: endpoints
            ),
            siteAddress: siteURL.absoluteString
        )
        let request = URLRequest(url: siteURL.appendingPathComponent("wp-json/protected"))

        // When
        let data = try await network.responseData(for: request)

        // Then
        XCTAssertEqual(String(data: data, encoding: .utf8), "success")
        let trace = scenario.trace
        XCTAssertEqual(trace.protectedRequestCount, 2)
        XCTAssertEqual(trace.loginEntryRequestCount, 1)
        XCTAssertEqual(trace.credentialRequestCount, 1)
        XCTAssertEqual(trace.nonceRequestCount, 1)
        XCTAssertEqual(trace.successfulProtectedRequestCount, 1)
        XCTAssertTrue(trace.credentialCookie?.contains(scenario.preflightCookie) == true)
        XCTAssertTrue(trace.nonceCookie?.contains(scenario.loginCookie) == true)
        XCTAssertEqual(trace.successfulProtectedNonce, "freshnonce")
        XCTAssertTrue(trace.successfulProtectedCookie?.contains(scenario.loginCookie) == true)
    }

    func test_wordpress_org_network_when_credentials_redirect_to_admin_base_then_fetches_nonce_without_following_redirect() async throws {
        // Given
        let scenario = CookieNonceLoopbackScenario(
            requiredInitialProtectedRequests: 1,
            credentialRedirectsToAdminBase: true
        )
        let server = try CookieNonceLoopbackServer(handler: scenario.response)
        defer { server.stop() }
        let siteURL = server.siteURL
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: siteURL.appendingPathComponent("custom-entry"),
            adminBaseURL: siteURL.appendingPathComponent("private-admin", isDirectory: true)
        )
        let network = WordPressOrgNetwork(
            configuration: CookieNonceAuthenticatorConfiguration(
                username: sampleUser,
                password: samplePassword,
                endpoints: endpoints
            ),
            siteAddress: siteURL.absoluteString
        )
        let request = URLRequest(url: siteURL.appendingPathComponent("wp-json/protected"))

        // When
        let data = try await network.responseData(for: request)

        // Then
        XCTAssertEqual(String(data: data, encoding: .utf8), "success")
        let trace = scenario.trace
        XCTAssertEqual(trace.protectedRequestCount, 2)
        XCTAssertEqual(trace.loginEntryRequestCount, 1)
        XCTAssertEqual(trace.credentialRequestCount, 1)
        XCTAssertEqual(trace.adminBaseRequestCount, 0)
        XCTAssertEqual(trace.nonceRequestCount, 1)
        XCTAssertEqual(trace.successfulProtectedRequestCount, 1)
        XCTAssertTrue(trace.credentialCookie?.contains(scenario.preflightCookie) == true)
        XCTAssertTrue(trace.nonceCookie?.contains(scenario.loginCookie) == true)
        XCTAssertEqual(trace.successfulProtectedNonce, "freshnonce")
        XCTAssertTrue(trace.successfulProtectedCookie?.contains(scenario.loginCookie) == true)
    }

    func test_default_application_password_use_case_with_custom_endpoints_authenticates_and_maps_password() async throws {
        // Given
        let passwordUUID = "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e"
        let generatedPassword = "generated-password"
        let responseBody = Data(#"{"uuid":"\#(passwordUUID)","password":"\#(generatedPassword)"}"#.utf8)
        let scenario = CookieNonceLoopbackScenario(
            requiredInitialProtectedRequests: 1,
            protectedMethod: "POST",
            protectedTarget: "/wp-json/wp/v2/users/me/application-passwords",
            successfulProtectedBody: responseBody
        )
        let server = try CookieNonceLoopbackServer(handler: scenario.response)
        defer { server.stop() }
        let siteURL = server.siteURL
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: siteURL.appendingPathComponent("custom-entry"),
            adminBaseURL: siteURL.appendingPathComponent("private-admin", isDirectory: true)
        )
        let storage = MockApplicationPasswordStorage()
        let sut = try DefaultApplicationPasswordUseCase(
            username: sampleUser,
            password: samplePassword,
            siteAddress: siteURL.absoluteString,
            authenticationEndpoints: endpoints,
            storage: storage,
            rootCache: MockRESTAPIRootCache(
                stubbedRoot: siteURL.appendingPathComponent("wp-json", isDirectory: true).absoluteString
            )
        )

        // When
        let password = try await sut.generateNewPassword()

        // Then
        XCTAssertEqual(password.wpOrgUsername, sampleUser)
        XCTAssertEqual(password.password.secretValue, generatedPassword)
        XCTAssertEqual(password.uuid, passwordUUID)
        XCTAssertEqual(storage.applicationPassword, password)
        let trace = scenario.trace
        XCTAssertEqual(trace.protectedRequestCount, 2)
        XCTAssertEqual(trace.loginEntryRequestCount, 1)
        XCTAssertEqual(trace.credentialRequestCount, 1)
        XCTAssertEqual(trace.nonceRequestCount, 1)
        XCTAssertEqual(trace.successfulProtectedRequestCount, 1)
        XCTAssertTrue(trace.credentialCookie?.contains(scenario.preflightCookie) == true)
        XCTAssertTrue(trace.nonceCookie?.contains(scenario.loginCookie) == true)
        XCTAssertEqual(trace.successfulProtectedNonce, "freshnonce")
        XCTAssertTrue(trace.successfulProtectedCookie?.contains(scenario.loginCookie) == true)
    }

    func test_wordpress_org_network_when_protected_requests_are_concurrent_then_coalesces_authentication_and_retries_all() async throws {
        // Given
        let scenario = CookieNonceLoopbackScenario(requiredInitialProtectedRequests: 2)
        let server = try CookieNonceLoopbackServer(handler: scenario.response)
        defer { server.stop() }
        let siteURL = server.siteURL
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: siteURL.appendingPathComponent("custom-entry"),
            adminBaseURL: siteURL.appendingPathComponent("private-admin", isDirectory: true)
        )
        let network = WordPressOrgNetwork(
            configuration: CookieNonceAuthenticatorConfiguration(
                username: sampleUser,
                password: samplePassword,
                endpoints: endpoints
            ),
            siteAddress: siteURL.absoluteString
        )
        let request = URLRequest(url: siteURL.appendingPathComponent("wp-json/protected"))

        // When
        async let firstResponse = responseData(for: request, using: network)
        async let secondResponse = responseData(for: request, using: network)
        let responses = try await (firstResponse, secondResponse)

        // Then
        XCTAssertEqual(
            [responses.0, responses.1].compactMap { String(data: $0, encoding: .utf8) },
            ["success", "success"]
        )
        let trace = scenario.trace
        XCTAssertEqual(trace.protectedRequestCount, 4)
        XCTAssertEqual(trace.loginEntryRequestCount, 1)
        XCTAssertEqual(trace.credentialRequestCount, 1)
        XCTAssertEqual(trace.nonceRequestCount, 1)
        XCTAssertEqual(trace.successfulProtectedRequestCount, 2)
    }

    func test_wordpress_org_network_when_credentials_receive_307_or_308_then_does_not_contact_redirect_target() async throws {
        for statusCode in [307, 308] {
            // Given
            let scenario = CookieNonceLoopbackScenario(
                requiredInitialProtectedRequests: 1,
                credentialRedirectStatusCode: statusCode
            )
            let server = try CookieNonceLoopbackServer(handler: scenario.response)
            let siteURL = server.siteURL
            let endpoints = try CookieNonceAuthenticationEndpoints(
                siteURL: siteURL,
                loginEntryURL: siteURL.appendingPathComponent("custom-entry"),
                adminBaseURL: siteURL.appendingPathComponent("private-admin", isDirectory: true)
            )
            let network = WordPressOrgNetwork(
                configuration: CookieNonceAuthenticatorConfiguration(
                    username: sampleUser,
                    password: samplePassword,
                    endpoints: endpoints
                ),
                siteAddress: siteURL.absoluteString
            )
            let request = URLRequest(url: siteURL.appendingPathComponent("wp-json/protected"))

            // When
            do {
                _ = try await network.responseData(for: request)
                XCTFail("Expected credential redirect \(statusCode) to fail")
            } catch {
                // Expected: the credential redirect is not the exact nonce target.
            }

            // Then
            let trace = scenario.trace
            XCTAssertEqual(trace.loginEntryRequestCount, 1)
            XCTAssertEqual(trace.credentialRequestCount, 1)
            XCTAssertEqual(trace.redirectTargetRequestCount, 0)
            XCTAssertEqual(trace.nonceRequestCount, 0)
            server.stop()
        }
    }
}

private extension CookieNonceAuthenticatorTests {
    func configuration() throws -> CookieNonceAuthenticatorConfiguration {
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: loginURL,
            adminBaseURL: adminURL
        )
        return CookieNonceAuthenticatorConfiguration(
            username: sampleUser,
            password: samplePassword,
            endpoints: endpoints
        )
    }

    func makeSession() -> Session {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CookieNonceAuthenticationURLProtocol.self]
        configuration.httpCookieStorage = HTTPCookieStorage()
        configuration.httpShouldSetCookies = true
        return Session(configuration: configuration)
    }

    func stubbedAuthenticator(
        configuration: CookieNonceAuthenticatorConfiguration? = nil
    ) throws -> CookieNonceAuthenticator {
        let configuration = try configuration ?? self.configuration()
        return CookieNonceAuthenticator(
            configuration: configuration,
            authenticationSessionFactory: { _ in
                let configuration = URLSessionConfiguration.ephemeral
                configuration.protocolClasses = [CookieNonceAuthenticationURLProtocol.self]
                configuration.httpCookieStorage = HTTPCookieStorage()
                configuration.httpShouldSetCookies = true
                return Session(configuration: configuration, redirectHandler: Redirector.doNotFollow)
            }
        )
    }

    func loginForm(action: String) -> String {
        "<form id=\"loginform\" name=\"loginform\" method=\"post\" action=\"\(action)\">" +
            "<input name=\"log\" id=\"user_login\" type=\"text\">" +
            "<input name=\"pwd\" id=\"user_pass\" type=\"password\"></form>"
    }

    func responseData(for request: URLRequest, using network: WordPressOrgNetwork) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            network.responseData(for: request) { (result: Result<Data, Swift.Error>) in
                continuation.resume(with: result)
            }
        }
    }
}

private final class CookieNonceAuthenticationURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int
        let headers: [String: String]
        let data: Data
    }

    private static let lock = NSLock()
    private static var stubs: [String: Stub] = [:]
    private static var requests: [URLRequest] = []

    static var receivedRequests: [URLRequest] {
        lock.withTestLock { requests }
    }

    static func stub(method: String, url: URL, statusCode: Int = 200, headers: [String: String] = [:], data: Data = Data()) {
        lock.withTestLock {
            stubs[key(method: method, url: url)] = Stub(statusCode: statusCode, headers: headers, data: data)
        }
    }

    static func reset() {
        lock.withTestLock {
            stubs.removeAll()
            requests.removeAll()
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let stub = Self.lock.withTestLock { () -> Stub? in
            Self.requests.append(Self.recordableRequest(from: request))
            return Self.stubs[Self.key(method: request.httpMethod ?? "GET", url: url)]
        }
        guard let stub,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: stub.statusCode,
                  httpVersion: nil,
                  headerFields: stub.headers
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func key(method: String, url: URL) -> String {
        "\(method) \(url.absoluteString)"
    }

    private static func recordableRequest(from request: URLRequest) -> URLRequest {
        guard request.httpBody == nil, let stream = request.httpBodyStream else {
            return request
        }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            body.append(contentsOf: buffer.prefix(count))
        }
        var recordedRequest = request
        recordedRequest.httpBody = body
        return recordedRequest
    }
}

private extension NSLock {
    func withTestLock<T>(_ operation: () -> T) -> T {
        lock()
        defer { unlock() }
        return operation()
    }
}

private final class CookieNonceLoopbackScenario: @unchecked Sendable {
    struct Trace {
        let protectedRequestCount: Int
        let loginEntryRequestCount: Int
        let credentialRequestCount: Int
        let nonceRequestCount: Int
        let successfulProtectedRequestCount: Int
        let credentialCookie: String?
        let nonceCookie: String?
        let successfulProtectedNonce: String?
        let successfulProtectedCookie: String?
        let redirectTargetRequestCount: Int
        let adminBaseRequestCount: Int
    }

    private let lock = NSLock()
    private let token = UUID().uuidString
    private let requiredInitialProtectedRequests: Int
    private let credentialRedirectStatusCode: Int?
    private let credentialRedirectsToAdminBase: Bool
    private let protectedMethod: String
    private let protectedTarget: String
    private let successfulProtectedBody: Data
    private var protectedRequestCount = 0
    private var loginEntryRequestCount = 0
    private var credentialRequestCount = 0
    private var nonceRequestCount = 0
    private var successfulProtectedRequestCount = 0
    private var credentialCookie: String?
    private var nonceCookie: String?
    private var successfulProtectedNonce: String?
    private var successfulProtectedCookie: String?
    private var redirectTargetRequestCount = 0
    private var adminBaseRequestCount = 0

    init(
        requiredInitialProtectedRequests: Int,
        credentialRedirectStatusCode: Int? = nil,
        credentialRedirectsToAdminBase: Bool = false,
        protectedMethod: String = "GET",
        protectedTarget: String = "/wp-json/protected",
        successfulProtectedBody: Data = Data("success".utf8)
    ) {
        self.requiredInitialProtectedRequests = requiredInitialProtectedRequests
        self.credentialRedirectStatusCode = credentialRedirectStatusCode
        self.credentialRedirectsToAdminBase = credentialRedirectsToAdminBase
        self.protectedMethod = protectedMethod
        self.protectedTarget = protectedTarget
        self.successfulProtectedBody = successfulProtectedBody
    }

    var preflightCookie: String { "preflight=\(token)" }
    var loginCookie: String { "wordpress_logged_in=\(token)" }

    var trace: Trace {
        lock.withTestLock {
            Trace(
                protectedRequestCount: protectedRequestCount,
                loginEntryRequestCount: loginEntryRequestCount,
                credentialRequestCount: credentialRequestCount,
                nonceRequestCount: nonceRequestCount,
                successfulProtectedRequestCount: successfulProtectedRequestCount,
                credentialCookie: credentialCookie,
                nonceCookie: nonceCookie,
                successfulProtectedNonce: successfulProtectedNonce,
                successfulProtectedCookie: successfulProtectedCookie,
                redirectTargetRequestCount: redirectTargetRequestCount,
                adminBaseRequestCount: adminBaseRequestCount
            )
        }
    }

    func response(to request: CookieNonceLoopbackServer.Request) -> CookieNonceLoopbackServer.Response {
        if request.method == protectedMethod, request.target == protectedTarget {
            return protectedResponse(to: request)
        }
        switch (request.method, request.target) {
        case ("GET", "/custom-entry"):
            waitForInitialProtectedRequests()
            lock.withTestLock { loginEntryRequestCount += 1 }
            return .init(
                statusCode: 200,
                headers: ["Set-Cookie": "\(preflightCookie); Path=/"],
                body: Data(loginForm.utf8)
            )
        case ("POST", "/custom-submit"):
            lock.withTestLock {
                credentialRequestCount += 1
                credentialCookie = request.headers["cookie"]
            }
            guard request.headers["cookie"]?.contains(preflightCookie) == true else {
                return .init(statusCode: 403)
            }
            if let credentialRedirectStatusCode {
                return .init(
                    statusCode: credentialRedirectStatusCode,
                    headers: ["Location": "/body-preserving-target"]
                )
            }
            return .init(
                statusCode: 302,
                headers: [
                    "Location": credentialRedirectsToAdminBase ?
                        "/private-admin/" : "/private-admin/admin-ajax.php?action=rest-nonce",
                    "Set-Cookie": "\(loginCookie); Path=/"
                ]
            )
        case ("GET", "/private-admin/"):
            lock.withTestLock { adminBaseRequestCount += 1 }
            return .init(statusCode: 200)
        case ("GET", "/private-admin/admin-ajax.php?action=rest-nonce"):
            lock.withTestLock {
                nonceRequestCount += 1
                nonceCookie = request.headers["cookie"]
            }
            guard request.headers["cookie"]?.contains(loginCookie) == true else {
                return .init(statusCode: 403)
            }
            return .init(statusCode: 200, body: Data("freshnonce".utf8))
        case (_, "/body-preserving-target"):
            lock.withTestLock { redirectTargetRequestCount += 1 }
            return .init(statusCode: 200)
        default:
            return .init(statusCode: 404)
        }
    }

    private func protectedResponse(to request: CookieNonceLoopbackServer.Request) -> CookieNonceLoopbackServer.Response {
        let isAuthenticated = request.headers["x-wp-nonce"] == "freshnonce" &&
            request.headers["cookie"]?.contains(loginCookie) == true
        lock.withTestLock {
            protectedRequestCount += 1
            if isAuthenticated {
                successfulProtectedRequestCount += 1
                successfulProtectedNonce = request.headers["x-wp-nonce"]
                successfulProtectedCookie = request.headers["cookie"]
            }
        }
        return isAuthenticated ? .init(statusCode: 200, body: successfulProtectedBody) : .init(statusCode: 401)
    }

    private func waitForInitialProtectedRequests() {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if lock.withTestLock({ protectedRequestCount >= requiredInitialProtectedRequests }) {
                return
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private var loginForm: String {
        "<form id=\"loginform\" name=\"loginform\" method=\"post\" action=\"/custom-submit\">" +
            "<input name=\"log\" id=\"user_login\" type=\"text\">" +
            "<input name=\"pwd\" id=\"user_pass\" type=\"password\"></form>"
    }
}

private final class CookieNonceLoopbackServer: @unchecked Sendable {
    struct Request {
        let method: String
        let target: String
        let headers: [String: String]
        let body: Data
    }

    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data

        init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body
        }
    }

    private let listener: NWListener
    private let handler: (Request) -> Response
    private let queue = DispatchQueue(label: "com.woocommerce.tests.cookie-nonce-loopback-listener")
    private var listeningPort: NWEndpoint.Port?

    var siteURL: URL {
        guard let listeningPort,
              let url = URL(string: "http://127.0.0.1:\(listeningPort.rawValue)") else {
            // A server without its listener-assigned port cannot produce any valid test request URL.
            preconditionFailure("Loopback server is not listening")
        }
        return url
    }

    init(handler: @escaping (Request) -> Response) throws {
        let listener = try NWListener(using: .tcp, on: .any)
        self.listener = listener
        self.handler = handler

        let ready = DispatchSemaphore(value: 0)
        let stateLock = NSLock()
        var startupError: Swift.Error?
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                ready.signal()
            case .failed(let error):
                stateLock.withTestLock { startupError = error }
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + 5) == .success,
              stateLock.withTestLock({ startupError == nil }),
              let port = listener.port else {
            listener.cancel()
            throw startupError ?? URLError(.cannotConnectToHost)
        }
        self.listeningPort = port
    }

    func stop() {
        listener.cancel()
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receive(on: connection, accumulatedData: Data())
    }

    private func receive(on connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            var accumulatedData = accumulatedData
            accumulatedData.append(data ?? Data())
            if let request = Self.parseRequest(from: accumulatedData) {
                send(handler(request), on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                receive(on: connection, accumulatedData: accumulatedData)
            }
        }
    }

    private func send(_ response: Response, on connection: NWConnection) {
        let reason = Self.reason(for: response.statusCode)
        var headerLines = [
            "HTTP/1.1 \(response.statusCode) \(reason)",
            "Content-Length: \(response.body.count)",
            "Connection: close"
        ]
        headerLines.append(contentsOf: response.headers.map { "\($0.key): \($0.value)" })
        var data = Data((headerLines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
        data.append(response.body)
        connection.send(content: data, completion: .contentProcessed { _ in connection.cancel() })
    }

    private static func parseRequest(from data: Data) -> Request? {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: separator),
              let headerText = String(data: data[..<headerRange.lowerBound], encoding: .utf8) else {
            return nil
        }
        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }
        let requestParts = requestLine.split(separator: " ")
        guard requestParts.count >= 2 else {
            return nil
        }
        let headers = Dictionary(uniqueKeysWithValues: lines.dropFirst().compactMap { line -> (String, String)? in
            guard let separatorIndex = line.firstIndex(of: ":") else {
                return nil
            }
            let name = String(line[..<separatorIndex]).lowercased()
            let value = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
            return (name, value)
        })
        let contentLength = Int(headers["content-length"] ?? "0") ?? 0
        let bodyStart = headerRange.upperBound
        guard data.count >= bodyStart + contentLength else {
            return nil
        }
        return Request(
            method: String(requestParts[0]),
            target: String(requestParts[1]),
            headers: headers,
            body: data.subdata(in: bodyStart..<(bodyStart + contentLength))
        )
    }

    private static func reason(for statusCode: Int) -> String {
        switch statusCode {
        case 200: "OK"
        case 302: "Found"
        case 307: "Temporary Redirect"
        case 308: "Permanent Redirect"
        case 401: "Unauthorized"
        case 403: "Forbidden"
        case 404: "Not Found"
        default: "Response"
        }
    }
}
