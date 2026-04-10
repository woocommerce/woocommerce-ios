import Testing
import Foundation
import WooFoundation
@testable import WooCommerce

@MainActor
struct PreLoginConnectivityToolViewModelTests {

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
        guard case .success(let summary) = result.state else {
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
        guard case .success(let summary) = result.state else {
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
        guard case .success(let summary) = result.state else {
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
        assertError(result.state)
    }

    // MARK: - API Discovery

    @Test func test_testAPIDiscovery_when_discovered_then_returns_success_and_sets_rootURL() async {
        // Given
        let sut = makeSUT(discoverAPIRoot: { _ in Self.discoveredAPIRoot })

        // When
        let result = await sut.testAPIDiscovery()

        // Then
        assertSuccess(result.state)
        #expect(sut.restAPIRootURL?.absoluteString == Self.discoveredAPIRoot)
    }

    @Test func test_testAPIDiscovery_when_not_discovered_then_returns_error_and_falls_back_to_rest_route() async {
        // Given
        let sut = makeSUT(discoverAPIRoot: { _ in nil })

        // When
        let result = await sut.testAPIDiscovery()

        // Then
        assertError(result.state)
        #expect(sut.restAPIRootURL?.absoluteString == "https://example.com/?rest_route=/")
    }

    // MARK: - WordPress REST API

    @Test func test_testWordPressRESTAPI_when_valid_json_then_returns_success() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"name":"My Site","namespaces":["wp/v2","wc/v3"]}"#
        mockSession.simulateResponse(for: "https://example.com/wp-json/", data: json.data(using: .utf8)!)
        let sut = await makeSUTWithDiscovery(session: mockSession)

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertSuccess(result.state)
    }

    @Test func test_testWordPressRESTAPI_when_fallback_rest_route_then_uses_fallback_url() async {
        // Given
        let mockSession = MockURLSession()
        let json = #"{"name":"My Site","namespaces":["wp/v2","wc/v3"]}"#
        mockSession.simulateResponse(for: "https://example.com/?rest_route=/", data: json.data(using: .utf8)!)
        let sut = await makeSUTWithFallbackDiscovery(session: mockSession)

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertSuccess(result.state)
    }

    @Test func test_testWordPressRESTAPI_when_no_api_root_then_returns_error() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertError(result.state)
    }

    @Test func test_testWordPressRESTAPI_when_404_then_returns_error() async {
        // Given
        let mockSession = MockURLSession()
        mockSession.simulateResponse(for: "https://example.com/wp-json/", statusCode: 404)
        let sut = await makeSUTWithDiscovery(session: mockSession)

        // When
        let result = await sut.testWordPressRESTAPI()

        // Then
        assertError(result.state)
    }

    // MARK: - WooCommerce API

    @Test func test_testWooCommerceAPI_when_wc_namespace_present_then_returns_success() async {
        // Given
        let sut = await makeSUTWithRESTAPIResponse(
            #"{"name":"My Site","namespaces":["wp/v2","wc/v3"]}"#
        )

        // When
        let result = await sut.testWooCommerceAPI()

        // Then
        assertSuccess(result.state)
    }

    @Test func test_testWooCommerceAPI_when_wc_namespace_missing_then_returns_error() async {
        // Given
        let sut = await makeSUTWithRESTAPIResponse(
            #"{"name":"My Site","namespaces":["wp/v2"]}"#
        )

        // When
        let result = await sut.testWooCommerceAPI()

        // Then
        assertError(result.state)
    }

    @Test func test_testWooCommerceAPI_when_no_rest_api_response_then_returns_error() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.testWooCommerceAPI()

        // Then
        assertError(result.state)
    }

    // MARK: - Application Passwords

    @Test func test_testApplicationPasswords_when_authorization_endpoint_present_then_returns_success() async {
        // Given
        let json = """
        {"name":"My Site","namespaces":["wp/v2"],\
        "authentication":{"application-passwords":{"endpoints":{"authorization":"https://example.com/wp-login.php?action=authorize_application"}}}}
        """
        let sut = await makeSUTWithRESTAPIResponse(json)

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertSuccess(result.state)
    }

    @Test func test_testApplicationPasswords_when_authentication_missing_then_returns_error() async {
        // Given
        let sut = await makeSUTWithRESTAPIResponse(
            #"{"name":"My Site","namespaces":["wp/v2"]}"#
        )

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertError(result.state)
    }

    @Test func test_testApplicationPasswords_when_no_rest_api_response_then_returns_error() async {
        // Given
        let sut = makeSUT()

        // When
        let result = await sut.testApplicationPasswords()

        // Then
        assertError(result.state)
    }

    // MARK: - Troubleshooting Description

    @Test func test_troubleshootingDescription_when_no_results_then_returns_nil() {
        // Given
        let sut = makeSUT()

        // When / Then
        #expect(sut.troubleshootingDescription() == nil)
    }

    // MARK: - Analytics Tracking

    @Test func test_startConnectivityTests_tracks_analytics_for_each_test() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let mockSession = MockURLSession()

        // Site info succeeds
        let siteInfoJSON = """
        {"name":"Store","urlAfterRedirects":"https://example.com",\
        "hasJetpack":false,"isJetpackActive":false,"isJetpackConnected":false,\
        "isWordPressDotCom":false,"isCommerceGarden":false,"isWordPress":true,"exists":true}
        """
        mockSession.simulateResponse(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            data: siteInfoJSON.data(using: .utf8)!
        )

        // REST API root returns valid JSON
        let restJSON = #"{"name":"Site","namespaces":["wp/v2","wc/v3"]}"#
        mockSession.simulateResponse(for: "https://example.com/wp-json/", data: restJSON.data(using: .utf8)!)

        // WooCommerce API returns valid JSON
        let wcJSON = #"{"namespace":"wc/v3","routes":{"/wc/v3":{}}}"#
        mockSession.simulateResponse(for: "https://example.com/wp-json/wc/v3", data: wcJSON.data(using: .utf8)!)

        // Application passwords returns 401 (standard challenge = success)
        let appPassJSON = #"{"code":"rest_not_logged_in","message":"Not logged in"}"#
        mockSession.simulateResponse(
            for: "https://example.com/wp-json/wp/v2/users/me/application-passwords",
            data: appPassJSON.data(using: .utf8)!,
            statusCode: 401
        )

        let sut = makeSUT(session: mockSession, analytics: analytics, discoverAPIRoot: { _ in
            "https://example.com/wp-json/"
        })

        // When
        await sut.startConnectivityTests()

        // Then
        let trackedEvents = analyticsProvider.receivedEvents.filter { $0 == "pre_login_connectivity_tool_request_response" }
        #expect(trackedEvents.count == 5)
    }

    @Test func test_startConnectivityTests_when_test_fails_then_tracks_failure() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let mockSession = MockURLSession()

        // Site info fails
        mockSession.simulateError(
            for: "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url=https://example.com",
            error: URLError(.timedOut)
        )

        let sut = makeSUT(session: mockSession, analytics: analytics)

        // When
        await sut.startConnectivityTests()

        // Then
        let trackedEvents = analyticsProvider.receivedEvents.filter { $0 == "pre_login_connectivity_tool_request_response" }
        #expect(trackedEvents.count == 5)

        let firstProperties = analyticsProvider.properties(for: "pre_login_connectivity_tool_request_response")
        #expect(firstProperties?["test"] as? String == "site_info")
        #expect(firstProperties?["success"] as? Bool == false)
        #expect(firstProperties?["time_taken"] as? Double != nil)
    }
}

// MARK: - Helpers
//
private extension PreLoginConnectivityToolViewModelTests {

    static let discoveredAPIRoot = "https://example.com/wp-json/"

    func makeSUT(siteURL: URL = URL(string: "https://example.com")!,
                 session: MockURLSession = MockURLSession(),
                 analytics: Analytics = ServiceLocator.analytics,
                 discoverAPIRoot: @escaping (String) async -> String? = { _ in nil }
    ) -> PreLoginConnectivityToolViewModel {
        PreLoginConnectivityToolViewModel(
            siteURL: siteURL,
            session: session,
            analytics: analytics,
            discoverAPIRoot: discoverAPIRoot
        )
    }

    func makeSUTWithFallbackDiscovery(session: MockURLSession) async -> PreLoginConnectivityToolViewModel {
        let sut = makeSUT(session: session, discoverAPIRoot: { _ in nil })
        _ = await sut.testAPIDiscovery()
        return sut
    }

    func makeSUTWithDiscovery(session: MockURLSession) async -> PreLoginConnectivityToolViewModel {
        let sut = makeSUT(session: session, discoverAPIRoot: { _ in Self.discoveredAPIRoot })
        _ = await sut.testAPIDiscovery()
        return sut
    }

    /// Creates a SUT with discovery done and the REST API root response already fetched (Test 3 complete).
    func makeSUTWithRESTAPIResponse(_ json: String) async -> PreLoginConnectivityToolViewModel {
        let mockSession = MockURLSession()
        mockSession.simulateResponse(for: Self.discoveredAPIRoot, data: json.data(using: .utf8)!)
        let sut = makeSUT(session: mockSession, discoverAPIRoot: { _ in Self.discoveredAPIRoot })
        _ = await sut.testAPIDiscovery()
        _ = await sut.testWordPressRESTAPI()
        return sut
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
