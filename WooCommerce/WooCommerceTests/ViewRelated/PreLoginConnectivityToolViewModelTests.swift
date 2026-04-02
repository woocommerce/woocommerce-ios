import Testing
import Foundation
import WooFoundation
@testable import WooCommerce

@MainActor
struct PreLoginConnectivityToolViewModelTests {

    // MARK: - Internet Connectivity

    @Test func test_testInternetConnectivity_when_reachable_then_returns_success() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.reachable(type: .ethernetOrWiFi))
        let sut = makeSUT(connectivityObserver: connectivityObserver)

        // When
        let result = sut.testInternetConnectivity()

        // Then
        assertSuccess(result)
    }

    @Test func test_testInternetConnectivity_when_not_reachable_then_returns_error() {
        // Given
        let connectivityObserver = MockConnectivityObserver()
        connectivityObserver.setStatus(.notReachable)
        let sut = makeSUT(connectivityObserver: connectivityObserver)

        // When
        let result = sut.testInternetConnectivity()

        // Then
        assertError(result)
    }

    // MARK: - Site Info

    @Test func test_testSiteInfo_when_wordpress_site_with_jetpack_then_returns_success_with_info() async {
        // Given
        let mockSession = MockURLSession()
        let json = """
        {"name":"My Store","description":"A store","urlAfterRedirects":"https://example.com",\
        "hasJetpack":true,"isJetpackActive":true,"isJetpackConnected":true,\
        "isWordPressDotCom":false,"isCommerceGarden":false,"isWordPress":true,"exists":true}
        """
        mockSession.simulateResponse(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            data: json.data(using: .utf8)!
        )
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testSiteInfo()

        // Then
        guard case .success(let summary, _) = result else {
            Issue.record("Expected .success but got \(result)")
            return
        }
        #expect(summary.contains("WordPress site detected"))
        #expect(summary.contains("Jetpack is installed and connected"))
    }

    @Test func test_testSiteInfo_when_commerce_garden_then_summary_includes_it() async {
        // Given
        let mockSession = MockURLSession()
        let json = """
        {"name":"Garden Store","urlAfterRedirects":"https://example.com",\
        "hasJetpack":true,"isJetpackActive":true,"isJetpackConnected":true,\
        "isWordPressDotCom":true,"isCommerceGarden":true,"isWordPress":true,"exists":true}
        """
        mockSession.simulateResponse(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            data: json.data(using: .utf8)!
        )
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testSiteInfo()

        // Then
        guard case .success(let summary, _) = result else {
            Issue.record("Expected .success but got \(result)")
            return
        }
        #expect(summary.contains("eCommerce Garden"))
    }

    @Test func test_testSiteInfo_when_no_jetpack_then_summary_shows_not_installed() async {
        // Given
        let mockSession = MockURLSession()
        let json = """
        {"name":"Simple Site","urlAfterRedirects":"https://example.com",\
        "hasJetpack":false,"isJetpackActive":false,"isJetpackConnected":false,\
        "isWordPressDotCom":false,"isCommerceGarden":false,"isWordPress":true,"exists":true}
        """
        mockSession.simulateResponse(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            data: json.data(using: .utf8)!
        )
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testSiteInfo()

        // Then
        guard case .success(let summary, _) = result else {
            Issue.record("Expected .success but got \(result)")
            return
        }
        #expect(summary.contains("Jetpack is not installed"))
    }

    @Test func test_testSiteInfo_when_request_fails_then_returns_error() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateError(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            error: URLError(.timedOut)
        )
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testSiteInfo()

        // Then
        assertError(result)
    }

    // MARK: - API Discovery

    @Test func test_testAPIDiscovery_when_link_header_present_then_returns_success_and_sets_rootURL() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateResponse(
            for: "https://example.com",
            statusCode: 200,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testAPIDiscovery()

        // Then
        assertSuccess(result)
        #expect(sut.restAPIRootURL?.absoluteString == "https://example.com/wp-json/")
    }

    @Test func test_testAPIDiscovery_when_no_link_header_then_returns_error() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateResponse(for: "https://example.com", statusCode: 200)
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testAPIDiscovery()

        // Then
        assertError(result)
        #expect(sut.restAPIRootURL == nil)
    }

    // MARK: - WordPress REST API

    @Test func test_testWordPressRESTAPI_when_valid_json_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"name":"My Site","namespaces":["wp/v2","wc/v3"]}"#
        mockSession.simulateResponse(for: "https://example.com/wp-json/", data: json.data(using: .utf8)!)
        let sut = makeSUT(session: mockSession)
        sut.restAPIRootURL = URL(string: "https://example.com/wp-json/")

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertSuccess(result)
    }

    @Test func test_testWordPressRESTAPI_when_no_api_root_then_returns_error() async {
        // Given
        let sut = makeSUT()
        // restAPIRootURL is nil

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertError(result)
    }

    @Test func test_testWordPressRESTAPI_when_404_then_returns_error() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateResponse(for: "https://example.com/wp-json/", statusCode: 404)
        let sut = makeSUT(session: mockSession)
        sut.restAPIRootURL = URL(string: "https://example.com/wp-json/")

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertError(result)
    }

    // MARK: - WooCommerce API

    @Test func test_testWooCommerceAPI_when_wc_namespace_present_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"namespace":"wc/v3","routes":{"/wc/v3":{}}}"#
        mockSession.simulateResponse(for: "https://example.com/wp-json/wc/v3", data: json.data(using: .utf8)!)
        let sut = makeSUT(session: mockSession)
        sut.restAPIRootURL = URL(string: "https://example.com/wp-json/")

        // When
        let result = await sut.testWooCommerceAPI()

        // Then
        assertSuccess(result)
    }

    @Test func test_testWooCommerceAPI_when_no_api_root_then_returns_error() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.testWooCommerceAPI()

        // Then
        assertError(result)
    }

    // MARK: - Application Passwords

    @Test func test_testApplicationPasswords_when_401_standard_challenge_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"code":"rest_not_logged_in","message":"Not logged in"}"#
        mockSession.simulateResponse(
            for: "https://example.com/wp-json/wp/v2/users/me/application-passwords",
            data: json.data(using: .utf8)!,
            statusCode: 401
        )
        let sut = makeSUT(session: mockSession)
        sut.restAPIRootURL = URL(string: "https://example.com/wp-json/")

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertSuccess(result)
    }

    @Test func test_testApplicationPasswords_when_disabled_then_returns_error() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"code":"application_passwords_disabled","message":"Disabled"}"#
        mockSession.simulateResponse(
            for: "https://example.com/wp-json/wp/v2/users/me/application-passwords",
            data: json.data(using: .utf8)!,
            statusCode: 401
        )
        let sut = makeSUT(session: mockSession)
        sut.restAPIRootURL = URL(string: "https://example.com/wp-json/")

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertError(result)
    }

    @Test func test_testApplicationPasswords_when_no_api_root_then_returns_error() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertError(result)
    }

    // MARK: - Login Page Analysis

    @Test func test_testLoginPage_when_clean_page_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        let html = "<html><body><form>Normal login form</form></body></html>"
        mockSession.simulateResponse(for: "https://example.com/wp-login.php", data: html.data(using: .utf8)!)
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testLoginPage()

        // Then
        assertSuccess(result)
    }

    @Test func test_testLoginPage_when_recaptcha_detected_then_returns_error_with_detail() async {
        // Given
        let mockSession = MockURLSession()
        let html = "<html><body><div class='g-recaptcha'>captcha</div></body></html>"
        mockSession.simulateResponse(for: "https://example.com/wp-login.php", data: html.data(using: .utf8)!)
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testLoginPage()

        // Then
        guard case .error(let summary, let detail) = result else {
            Issue.record("Expected .error but got \(result)")
            return
        }
        #expect(summary.contains("reCAPTCHA"))
        #expect(detail.contains("wp-login.php"))
    }

    @Test func test_testLoginPage_when_unreachable_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateError(for: "https://example.com/wp-login.php", error: URLError(.timedOut))
        let sut = makeSUT(session: mockSession)

        // When
        let result = await sut.testLoginPage()

        // Then
        assertSuccess(result)
    }

    // MARK: - Troubleshooting Description

    @Test func test_troubleshootingDescription_when_no_results_then_returns_nil() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.troubleshootingDescription() == nil)
    }

    // MARK: - Analytics

    @Test func test_analytics_when_opened_then_tracks_event() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        // When
        _ = makeSUT(analytics: analytics)

        // Then
        #expect(analyticsProvider.receivedEvents.contains("pre_login_connectivity_tool_opened"))
    }
}

// MARK: - Helpers
//
private extension PreLoginConnectivityToolViewModelTests {

    func makeSUT(siteURL: URL = URL(string: "https://example.com")!,
                 session: MockURLSession = MockURLSession(),
                 analytics: Analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
                 connectivityObserver: MockConnectivityObserver = {
                     let observer = MockConnectivityObserver()
                     observer.setStatus(.reachable(type: .ethernetOrWiFi))
                     return observer
                 }()) -> PreLoginConnectivityToolViewModel {
        PreLoginConnectivityToolViewModel(
            siteURL: siteURL,
            session: session,
            analytics: analytics,
            connectivityObserver: connectivityObserver
        )
    }

    func assertSuccess(_ state: PreLoginCheckState,
                       sourceLocation: SourceLocation = #_sourceLocation) {
        guard case .success = state else {
            Issue.record("Expected .success but got \(state)", sourceLocation: sourceLocation)
            return
        }
    }

    func assertError(_ state: PreLoginCheckState,
                     sourceLocation: SourceLocation = #_sourceLocation) {
        guard case .error = state else {
            Issue.record("Expected .error but got \(state)", sourceLocation: sourceLocation)
            return
        }
    }
}
