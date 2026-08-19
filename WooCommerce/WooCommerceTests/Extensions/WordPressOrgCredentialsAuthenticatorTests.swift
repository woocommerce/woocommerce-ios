import XCTest
import WebKit
import WordPressAuthenticator
import Fakes
import Yosemite
@testable import WooCommerce

@MainActor
final class WordPressOrgCredentialsAuthenticatorTests: XCTestCase {

    private let username = "test"
    private let password = "pwd"
    private let xmlrpc = "https://test.com/xmlrpc.php"
    private let options: [AnyHashable: Any] = [
        "login_url": ["value": "https://test.com/wp-login.php"],
        "admin_url": ["value": "https://test.com/wp-admin"],
        "software_version": ["value": "5.3.1"]
    ]

    func test_loginURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.loginURL, "https://test.com/wp-login.php")
    }

    func test_adminURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.adminURL, "https://test.com/wp-admin")
    }

    func test_authentication_endpoints_reject_https_to_http_downgrade() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "http://test.com/wp-login.php"],
            "admin_url": ["value": "https://test.com/wp-admin"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }

    func test_default_endpoints_normalize_trailing_slash_without_double_slashes() {
        // Given
        let credentials = WordPressOrgCredentials(
            username: username,
            password: password,
            xmlrpc: "https://test.com//xmlrpc.php",
            options: [:]
        )

        // Then
        XCTAssertEqual(credentials.authenticationEndpoints?.loginEntryURL.absoluteString, "https://test.com/wp-login.php")
        XCTAssertEqual(credentials.authenticationEndpoints?.adminBaseURL.absoluteString, "https://test.com/wp-admin/")
        XCTAssertEqual(credentials.loginURL, "https://test.com/wp-login.php")
        XCTAssertEqual(credentials.adminURL, "https://test.com/wp-admin")
    }

    func test_web_view_authentication_default_redirect_has_exactly_one_admin_path_separator() throws {
        // Given
        let credentials = WordPressOrgCredentials(
            username: username,
            password: password,
            xmlrpc: "https://test.com//xmlrpc.php",
            options: [:]
        )

        // When
        let request = try WKWebView().authenticateForWPOrg(with: credentials)
        let body = try XCTUnwrap(request.httpBody)
        let encodedParameters = try XCTUnwrap(String(data: body, encoding: .utf8))
        var components = URLComponents()
        components.percentEncodedQuery = encodedParameters
        let redirectURL = components.queryItems?.first(where: { $0.name == "redirect_to" })?.value

        // Then
        XCTAssertEqual(redirectURL, "https://test.com/wp-admin/admin-ajax.php?action=rest-nonce")
        XCTAssertFalse(redirectURL?.contains("/wp-admin//admin-ajax.php") == true)
    }

    func test_authentication_endpoints_accept_custom_same_site_options() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "https://test.com/custom-entry"],
            "admin_url": ["value": "https://test.com/private-admin"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertEqual(credentials.authenticationEndpoints?.loginEntryURL.absoluteString, "https://test.com/custom-entry")
        XCTAssertEqual(credentials.authenticationEndpoints?.adminBaseURL.absoluteString, "https://test.com/private-admin/")
    }

    func test_authentication_endpoints_reject_cross_origin_option() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "https://attacker.example/wp-login.php"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }

    func test_authentication_endpoints_reject_malformed_option_string() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": ":// malformed"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }

    func test_web_view_authentication_with_custom_endpoints_posts_to_configured_entry_and_redirects_to_policy_nonce() throws {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: [:])
        let endpoints = try makeEndpoints()

        // When
        let request = try WKWebView().authenticateForWPOrg(with: credentials, authenticationEndpoints: endpoints)

        // Then
        XCTAssertEqual(request.url, endpoints.loginEntryURL)
        XCTAssertEqual(request.url?.absoluteString, "https://test.com/custom-login?entry=1")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(try formValue(named: "log", in: request), username)
        XCTAssertEqual(try formValue(named: "pwd", in: request), password)
        XCTAssertEqual(try formValue(named: "redirect_to", in: request), try endpoints.nonceURL().absoluteString)
    }

    func test_web_view_authentication_with_endpoints_for_different_site_throws() throws {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: [:])
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: XCTUnwrap(URL(string: "https://other.example")))

        // Then
        XCTAssertThrowsError(try WKWebView().authenticateForWPOrg(with: credentials, authenticationEndpoints: endpoints))
    }

    func test_resolve_wporg_authentication_prefers_extra_credentials_and_looks_up_their_exact_endpoints() throws {
        // Given
        let extra: Yosemite.Credentials = .wporg(username: "extra", password: "extra-pass", siteAddress: "https://test.com")
        let current: Yosemite.Credentials = .wporg(username: "current", password: "current-pass", siteAddress: "https://current.example")
        let endpoints = try makeEndpoints()
        var lookedUpCredentials: Yosemite.Credentials?

        // When
        let context = AuthenticatedWebViewController.resolveWPOrgAuthentication(
            extraCredentials: extra,
            currentCredentials: current,
            authenticationEndpointLookup: { credentials in
                lookedUpCredentials = credentials
                return endpoints
            }
        )

        // Then
        XCTAssertEqual(lookedUpCredentials, extra)
        XCTAssertEqual(context?.credentials.username, "extra")
        XCTAssertEqual(context?.credentials.password, "extra-pass")
        XCTAssertEqual(context?.authenticationEndpoints, endpoints)
    }

    func test_resolve_wporg_authentication_without_persisted_endpoints_uses_selected_credentials_defaults() throws {
        // Given
        let current: Yosemite.Credentials = .wporg(username: username, password: password, siteAddress: "https://test.com")

        // When
        let context = AuthenticatedWebViewController.resolveWPOrgAuthentication(
            extraCredentials: .wpcom(username: "wpcom", authToken: "token", siteAddress: "https://wordpress.com"),
            currentCredentials: current,
            authenticationEndpointLookup: { _ in nil }
        )

        // Then
        XCTAssertEqual(context?.credentials.username, username)
        XCTAssertEqual(context?.authenticationEndpoints.loginEntryURL.absoluteString, "https://test.com/wp-login.php")
        XCTAssertEqual(context?.authenticationEndpoints.adminBaseURL.absoluteString, "https://test.com/wp-admin/")
    }

    func test_navigation_gate_allows_initial_main_frame_post_only_once() throws {
        // Given
        let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
        var gate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )

        // When
        let firstDecision = gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false)
        let repeatedDecision = gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false)

        // Then
        XCTAssertEqual(firstDecision, .allowCredentialPost)
        XCTAssertEqual(repeatedDecision, .cancelAndFinish)
    }

    func test_navigation_gate_rejects_subframe_and_download_credential_posts() throws {
        // Given
        let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
        var subframeGate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )
        var downloadGate = subframeGate

        // Then
        XCTAssertEqual(
            subframeGate.decision(for: request, isMainFrame: false, shouldPerformDownload: false),
            .cancelAndFinish
        )
        XCTAssertEqual(
            downloadGate.decision(for: request, isMainFrame: true, shouldPerformDownload: true),
            .cancelAndFinish
        )
    }

    func test_navigation_gate_rewrites_preserved_destination_post_once_then_accepts_clean_get_and_exact_2xx_response() throws {
        // Given
        let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
        let nonceURL = try endpoints.nonceURL()
        var gate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )
        XCTAssertEqual(gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false), .allowCredentialPost)
        var preservedPost = URLRequest(url: nonceURL)
        preservedPost.httpMethod = "POST"
        preservedPost.httpBody = Data("credentials".utf8)

        // When
        let preservedPostDecision = gate.decision(for: preservedPost, isMainFrame: true, shouldPerformDownload: false)
        let cleanGet = URLRequest(url: nonceURL)
        let cleanGetDecision = gate.decision(for: cleanGet, isMainFrame: true, shouldPerformDownload: false)
        let response = try XCTUnwrap(HTTPURLResponse(url: nonceURL, statusCode: 200, httpVersion: nil, headerFields: nil))
        let responseDecision = gate.decision(for: response, isMainFrame: true, canShowMIMEType: true)

        // Then
        XCTAssertEqual(preservedPostDecision, .cancelAndLoadDestination(nonceURL))
        XCTAssertEqual(cleanGetDecision, .allowDestination)
        XCTAssertEqual(responseDecision, .allowAndFinish(nonceURL))
    }

    func test_navigation_gate_rejects_arbitrary_same_site_and_cross_site_destinations() throws {
        // Given
        let disallowedURLs = [
            try XCTUnwrap(URL(string: "https://test.com/wp-admin/admin-ajax.php?action=other")),
            try XCTUnwrap(URL(string: "https://test.com/another-admin/admin-ajax.php?action=rest-nonce")),
            try XCTUnwrap(URL(string: "https://attacker.example/wp-admin/admin-ajax.php?action=rest-nonce"))
        ]

        // When
        let decisions = try disallowedURLs.map { url -> WPOrgWebViewAuthenticationNavigationGate.Decision in
            let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
            var gate = try WPOrgWebViewAuthenticationNavigationGate(
                authenticationRequest: request,
                authenticationEndpoints: endpoints
            )
            _ = gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false)
            return gate.decision(for: URLRequest(url: url), isMainFrame: true, shouldPerformDownload: false)
        }

        // Then
        XCTAssertEqual(decisions, Array(repeating: .cancelAndFinish, count: disallowedURLs.count))
    }

    func test_navigation_gate_accepts_controlled_default_port_https_promotion_but_rejects_downgrade_afterwards() throws {
        // Given
        let siteURL = try XCTUnwrap(URL(string: "http://test.com:80"))
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: siteURL)
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: "http://test.com/xmlrpc.php", options: [:])
        let request = try WKWebView().authenticateForWPOrg(with: credentials, authenticationEndpoints: endpoints)
        var gate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )
        _ = gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false)
        let insecureAdminURL = try endpoints.derivedAdminBaseURL()
        let secureNonceURL = try XCTUnwrap(URL(string: "https://test.com/wp-admin/admin-ajax.php?action=rest-nonce"))

        // When
        let adminDecision = gate.decision(for: URLRequest(url: insecureAdminURL), isMainFrame: true, shouldPerformDownload: false)
        let promotedDecision = gate.decision(for: URLRequest(url: secureNonceURL), isMainFrame: true, shouldPerformDownload: false)
        let insecureNonceURL = try endpoints.nonceURL()
        let downgradeDecision = gate.decision(for: URLRequest(url: insecureNonceURL), isMainFrame: true, shouldPerformDownload: false)

        // Then
        XCTAssertEqual(adminDecision, .allowDestination)
        XCTAssertEqual(promotedDecision, .allowDestination)
        XCTAssertEqual(downgradeDecision, .cancelAndFinish)
    }

    func test_navigation_gate_bounds_redirect_action_chain_without_double_counting_redirect_responses() throws {
        // Given
        let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
        var gate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )
        XCTAssertEqual(gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false), .allowCredentialPost)
        let loginURL = try XCTUnwrap(request.url)
        let loginResponse = try XCTUnwrap(HTTPURLResponse(url: loginURL, statusCode: 302, httpVersion: nil, headerFields: nil))
        XCTAssertEqual(gate.decision(for: loginResponse, isMainFrame: true, canShowMIMEType: false), .allowContinuation)
        let adminURL = endpoints.adminBaseURL
        let nonceURL = try endpoints.nonceURL()
        let allowedURLs = [adminURL, nonceURL, adminURL]

        // When
        let allowedDecisions = try allowedURLs.map { url -> WPOrgWebViewAuthenticationNavigationGate.Decision in
            let decision = gate.decision(for: URLRequest(url: url), isMainFrame: true, shouldPerformDownload: false)
            let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 302, httpVersion: nil, headerFields: nil))
            XCTAssertEqual(gate.decision(for: response, isMainFrame: true, canShowMIMEType: false), .allowContinuation)
            return decision
        }
        let overLimitDecision = gate.decision(for: URLRequest(url: nonceURL), isMainFrame: true, shouldPerformDownload: false)

        // Then
        XCTAssertEqual(allowedDecisions, Array(repeating: .allowDestination, count: allowedURLs.count))
        XCTAssertEqual(overLimitDecision, .cancelAndFinish)
    }

    func test_navigation_gate_allows_exact_configured_admin_base_get() throws {
        // Given
        let (request, endpoints) = try makeAuthenticationRequestAndEndpoints()
        var gate = try WPOrgWebViewAuthenticationNavigationGate(
            authenticationRequest: request,
            authenticationEndpoints: endpoints
        )
        _ = gate.decision(for: request, isMainFrame: true, shouldPerformDownload: false)

        // When
        let decision = gate.decision(
            for: URLRequest(url: endpoints.adminBaseURL),
            isMainFrame: true,
            shouldPerformDownload: false
        )

        // Then
        XCTAssertEqual(decision, .allowDestination)
    }

    func test_controller_boundary_rewrites_preserved_post_and_finishes_only_after_exact_2xx_response() throws {
        // Given
        let harness = try makeAuthenticatedControllerHarness()
        defer { harness.cleanup() }
        let (sut, webView, endpoints, initialURL) = (harness.controller, harness.webView, harness.endpoints, harness.initialURL)
        sut.loadViewIfNeeded()
        let credentialRequest = try XCTUnwrap(webView.loadedRequests.first)
        XCTAssertEqual(
            sut.decideSiteCredentialNavigation(for: credentialRequest, isMainFrame: true, shouldPerformDownload: false),
            .allow
        )
        let nonceURL = try endpoints.nonceURL()
        var preservedPost = URLRequest(url: nonceURL)
        preservedPost.httpMethod = "POST"
        preservedPost.httpBody = Data("credentials".utf8)

        // When
        let preservedPolicy = sut.decideSiteCredentialNavigation(
            for: preservedPost,
            isMainFrame: true,
            shouldPerformDownload: false
        )
        let cleanGet = try XCTUnwrap(webView.loadedRequests.last)
        let cleanGetPolicy = sut.decideSiteCredentialNavigation(for: cleanGet, isMainFrame: true, shouldPerformDownload: false)
        let response = try XCTUnwrap(HTTPURLResponse(url: nonceURL, statusCode: 200, httpVersion: nil, headerFields: nil))
        let responsePolicy = sut.decideSiteCredentialNavigation(
            for: response,
            isMainFrame: true,
            canShowMIMEType: true
        )

        // Then
        XCTAssertEqual(preservedPolicy, .cancel)
        XCTAssertEqual(cleanGet.url, nonceURL)
        XCTAssertEqual(cleanGet.httpMethod, "GET")
        XCTAssertNil(cleanGet.httpBody)
        XCTAssertEqual(cleanGetPolicy, .allow)
        XCTAssertEqual(responsePolicy, .cancel)
        XCTAssertEqual(webView.loadedRequests.last?.url, initialURL)
        XCTAssertNil(
            sut.decideSiteCredentialNavigation(for: URLRequest(url: initialURL), isMainFrame: true, shouldPerformDownload: false)
        )
    }

    func test_policy_cancellation_does_not_supersede_scheduled_clean_get_but_clean_get_failure_falls_back_once() throws {
        // Given
        let harness = try makeAuthenticatedControllerHarness()
        defer { harness.cleanup() }
        let (sut, webView, endpoints, initialURL) = (harness.controller, harness.webView, harness.endpoints, harness.initialURL)
        sut.loadViewIfNeeded()
        let credentialRequest = try XCTUnwrap(webView.loadedRequests.first)
        let credentialNavigation = try XCTUnwrap(webView.loadedNavigations.first)
        XCTAssertEqual(
            sut.decideSiteCredentialNavigation(for: credentialRequest, isMainFrame: true, shouldPerformDownload: false),
            .allow
        )
        let nonceURL = try endpoints.nonceURL()
        var preservedPost = URLRequest(url: nonceURL)
        preservedPost.httpMethod = "POST"
        preservedPost.httpBody = Data("credentials".utf8)

        // When
        let preservedPolicy = sut.decideSiteCredentialNavigation(
            for: preservedPost,
            isMainFrame: true,
            shouldPerformDownload: false
        )
        sut.webView(
            webView,
            didFailProvisionalNavigation: credentialNavigation,
            withError: URLError(.cancelled)
        )
        let cleanNavigation = try XCTUnwrap(webView.loadedNavigations.last)
        sut.webView(webView, didFailProvisionalNavigation: cleanNavigation, withError: URLError(.cannotConnectToHost))
        sut.webView(webView, didFailProvisionalNavigation: cleanNavigation, withError: URLError(.cannotConnectToHost))

        // Then
        XCTAssertEqual(preservedPolicy, .cancel)
        XCTAssertEqual(webView.loadedRequests.map(\.url), [credentialRequest.url, nonceURL, initialURL])
        XCTAssertEqual(webView.loadedRequests[1].httpMethod, "GET")
        XCTAssertNil(webView.loadedRequests[1].httpBody)
    }

    func test_controller_with_mismatched_persisted_endpoint_identity_falls_back_to_unauthenticated_initial_url() throws {
        // Given
        let credentials: Yosemite.Credentials = .wporg(username: username, password: password, siteAddress: "https://test.com")
        let sessionManager = MockSessionManager()
        sessionManager.defaultCredentials = credentials
        sessionManager.defaultSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://test.com")
        sessionManager.cookieNonceAuthenticationEndpointsToReturn = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://other.example"))
        )
        let initialURL = try XCTUnwrap(URL(string: "https://test.com/products/13"))
        let webView = RecordingWKWebView()
        let sut = AuthenticatedWebViewController(
            stores: DefaultStoresManager(sessionManager: sessionManager),
            viewModel: StubAuthenticatedWebViewModel(initialURL: initialURL),
            extraCredentials: nil,
            webView: webView
        )

        // When
        sut.loadViewIfNeeded()

        // Then
        XCTAssertEqual(webView.loadedRequests.map(\.url), [initialURL])
    }

    func test_controller_rewrites_preserved_post_and_never_loads_attacker_request() throws {
        // Given
        let harness = try makeAuthenticatedControllerHarness()
        defer { harness.cleanup() }
        let (sut, webView, endpoints) = (harness.controller, harness.webView, harness.endpoints)
        sut.loadViewIfNeeded()
        let credentialRequest = try XCTUnwrap(webView.loadedRequests.first)
        let credentialPolicy = sut.decideSiteCredentialNavigation(
            for: credentialRequest,
            isMainFrame: true,
            shouldPerformDownload: false
        )
        XCTAssertEqual(credentialPolicy, .allow)
        let nonceURL = try endpoints.nonceURL()
        var preservedPost = URLRequest(url: nonceURL)
        preservedPost.httpMethod = "POST"
        preservedPost.httpBody = Data("credentials".utf8)

        // When
        let preservedPolicy = sut.decideSiteCredentialNavigation(
            for: preservedPost,
            isMainFrame: true,
            shouldPerformDownload: false
        )
        let attackerURL = try XCTUnwrap(URL(string: "https://attacker.example/collect"))
        let attackerPolicy = sut.decideSiteCredentialNavigation(
            for: URLRequest(url: attackerURL),
            isMainFrame: true,
            shouldPerformDownload: false
        )

        // Then
        XCTAssertEqual(preservedPolicy, .cancel)
        XCTAssertTrue(webView.loadedRequests.contains { $0.url == nonceURL && $0.httpMethod == "GET" })
        XCTAssertEqual(attackerPolicy, .cancel)
        XCTAssertFalse(webView.loadedRequests.contains { $0.url == attackerURL })
    }

    func test_process_termination_during_authentication_loads_one_fresh_initial_get_and_clears_gate() throws {
        // Given
        let harness = try makeAuthenticatedControllerHarness()
        defer { harness.cleanup() }
        let (sut, webView, initialURL) = (harness.controller, harness.webView, harness.initialURL)
        sut.loadViewIfNeeded()
        let credentialRequest = try XCTUnwrap(webView.loadedRequests.first)
        XCTAssertEqual(
            sut.decideSiteCredentialNavigation(for: credentialRequest, isMainFrame: true, shouldPerformDownload: false),
            .allow
        )

        // When
        sut.webViewWebContentProcessDidTerminate(webView)
        sut.webViewWebContentProcessDidTerminate(webView)

        // Then
        XCTAssertEqual(webView.loadedRequests.count, 2)
        XCTAssertEqual(webView.loadedRequests.last?.url, initialURL)
        XCTAssertEqual(webView.loadedRequests.last?.httpMethod, "GET")
        XCTAssertNil(webView.loadedRequests.last?.httpBody)
        XCTAssertNil(
            sut.decideSiteCredentialNavigation(for: URLRequest(url: initialURL), isMainFrame: true, shouldPerformDownload: false)
        )
    }

    private func makeEndpoints() throws -> CookieNonceAuthenticationEndpoints {
        try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://test.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://test.com/custom-login?entry=1")),
            adminBaseURL: XCTUnwrap(URL(string: "https://test.com/private-admin/"))
        )
    }

    private func makeAuthenticationRequestAndEndpoints() throws -> (URLRequest, CookieNonceAuthenticationEndpoints) {
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: [:])
        let endpoints = try makeEndpoints()
        return (try WKWebView().authenticateForWPOrg(with: credentials, authenticationEndpoints: endpoints), endpoints)
    }

    private func makeAuthenticatedControllerHarness() throws -> (
        controller: AuthenticatedWebViewController,
        webView: RecordingWKWebView,
        endpoints: CookieNonceAuthenticationEndpoints,
        initialURL: URL,
        cleanup: () -> Void
    ) {
        let suiteName = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let sessionManager = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentials: Yosemite.Credentials = .wporg(username: username, password: password, siteAddress: "https://test.com")
        let endpoints = try makeEndpoints()
        let initialURL = try XCTUnwrap(URL(string: "https://test.com/products/13"))
        sessionManager.defaultCredentials = credentials
        sessionManager.defaultSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://test.com")
        sessionManager.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)
        let webView = RecordingWKWebView()
        let controller = AuthenticatedWebViewController(
            stores: MockStoresManager(sessionManager: sessionManager),
            viewModel: StubAuthenticatedWebViewModel(initialURL: initialURL),
            extraCredentials: nil,
            webView: webView,
            siteCredentialReplacementScheduler: { $0() }
        )
        return (controller, webView, endpoints, initialURL, { defaults.removePersistentDomain(forName: suiteName) })
    }

    private func formValue(named name: String, in request: URLRequest) throws -> String? {
        let body = try XCTUnwrap(request.httpBody)
        let encodedParameters = try XCTUnwrap(String(data: body, encoding: .utf8))
        var components = URLComponents()
        components.percentEncodedQuery = encodedParameters
        return components.queryItems?.first(where: { $0.name == name })?.value
    }
}

@MainActor
private final class RecordingWKWebView: WKWebView {
    private(set) var loadedRequests: [URLRequest] = []
    private(set) var loadedNavigations: [WKNavigation] = []

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadedRequests.append(request)
        let navigation = StubNavigation()
        loadedNavigations.append(navigation)
        return navigation
    }
}

private final class StubNavigation: WKNavigation { }

private final class StubAuthenticatedWebViewModel: AuthenticatedWebViewModel {
    let title = ""
    let initialURL: URL?

    init(initialURL: URL) {
        self.initialURL = initialURL
    }

    func handleDismissal() { }
    func handleRedirect(for url: URL?) { }
    func decidePolicy(for navigationURL: URL) async -> WKNavigationActionPolicy { .allow }
}
