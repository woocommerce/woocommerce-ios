import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct AuthenticatedWebViewModelTests {

    private static let testURLs = [
        URL(string: "https://wordpress.com/jetpack/connect?url=%@&mobile_redirect=%@&from=mobile"),
        URL(string: "https://jetpack.wordpress.com/jetpack.authorize"),
        URL(string: "https://woocommerce.com/products/product-bundles/"),
        URL(string: "https://jetpack.com/stats/"),
        URL(string: "https://adpurchase.wordpress.com/checkout/order-pay/123/")
    ]
    private let siteURL = "http://example.com"

    @Test @MainActor func test_decidePolicy_when_initial_url_main_frame_response_is_http_error_then_calls_handler_with_status_code() async throws {
        // Given
        var receivedStatusCodes: [Int] = []
        let url = try #require(URL(string: siteURL))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url, initialURLHTTPErrorHandler: { statusCode in
            receivedStatusCodes.append(statusCode)
        })

        // When
        let policy = await viewModel.decidePolicy(for: response, isForMainFrame: true)

        // Then
        #expect(policy == .allow)
        #expect(receivedStatusCodes == [404])
    }

    @Test @MainActor func test_decidePolicy_when_main_frame_response_succeeds_then_does_not_call_handler() async throws {
        // Given
        var handlerWasCalled = false
        let url = try #require(URL(string: siteURL))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url, initialURLHTTPErrorHandler: { _ in
            handlerWasCalled = true
        })

        // When
        _ = await viewModel.decidePolicy(for: response, isForMainFrame: true)

        // Then
        #expect(!handlerWasCalled)
    }

    @Test @MainActor func test_decidePolicy_when_subframe_response_is_http_error_then_does_not_call_handler() async throws {
        // Given
        var handlerWasCalled = false
        let url = try #require(URL(string: siteURL))
        let response = try #require(HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url, initialURLHTTPErrorHandler: { _ in
            handlerWasCalled = true
        })

        // When
        _ = await viewModel.decidePolicy(for: response, isForMainFrame: false)

        // Then
        #expect(!handlerWasCalled)
    }

    @Test @MainActor func test_decidePolicy_when_other_main_frame_response_is_http_error_then_does_not_call_handler() async throws {
        // Given
        var handlerWasCalled = false
        let initialURL = try #require(URL(string: siteURL + "/preview"))
        let otherURL = try #require(URL(string: siteURL + "/other"))
        let response = try #require(HTTPURLResponse(url: otherURL, statusCode: 404, httpVersion: nil, headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: initialURL, initialURLHTTPErrorHandler: { _ in
            handlerWasCalled = true
        })

        // When
        _ = await viewModel.decidePolicy(for: response, isForMainFrame: true)

        // Then
        #expect(!handlerWasCalled)
    }

    @Test @MainActor func test_decidePolicy_when_non_preview_responses_precede_initial_url_error_then_calls_handler_once() async throws {
        // Given
        var receivedStatusCodes: [Int] = []
        let initialURL = try #require(URL(string: siteURL))
        let otherURL = try #require(URL(string: siteURL + "/other"))
        let subframeResponse = try #require(HTTPURLResponse(url: initialURL,
                                                           statusCode: 500,
                                                           httpVersion: nil,
                                                           headerFields: nil))
        let otherPageResponse = try #require(HTTPURLResponse(url: otherURL,
                                                            statusCode: 404,
                                                            httpVersion: nil,
                                                            headerFields: nil))
        let previewResponse = try #require(HTTPURLResponse(url: initialURL,
                                                          statusCode: 404,
                                                          httpVersion: nil,
                                                          headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: initialURL, initialURLHTTPErrorHandler: { statusCode in
            receivedStatusCodes.append(statusCode)
        })

        // When
        _ = await viewModel.decidePolicy(for: subframeResponse, isForMainFrame: false)
        _ = await viewModel.decidePolicy(for: otherPageResponse, isForMainFrame: true)
        _ = await viewModel.decidePolicy(for: previewResponse, isForMainFrame: true)

        // Then
        #expect(receivedStatusCodes == [404])
    }

    @Test @MainActor func test_decidePolicy_when_initial_url_response_has_arrived_then_ignores_later_response() async throws {
        // Given
        var handlerWasCalled = false
        let url = try #require(URL(string: siteURL))
        let successfulResponse = try #require(HTTPURLResponse(url: url,
                                                             statusCode: 200,
                                                             httpVersion: nil,
                                                             headerFields: nil))
        let errorResponse = try #require(HTTPURLResponse(url: url,
                                                        statusCode: 404,
                                                        httpVersion: nil,
                                                        headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: url, initialURLHTTPErrorHandler: { _ in
            handlerWasCalled = true
        })

        // When
        _ = await viewModel.decidePolicy(for: successfulResponse, isForMainFrame: true)
        _ = await viewModel.decidePolicy(for: errorResponse, isForMainFrame: true)

        // Then
        #expect(!handlerWasCalled)
    }

    @Test(arguments: Self.testURLs)
    func authenticationFlow_for_wpcom_pages_when_wpcom_credentials_are_available(_ initialURL: URL?) throws {
        // Given
        let unwrappedURL = try #require(initialURL)
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: unwrappedURL)
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: true,
                                                              wporgCredentialsAvailable: false)

        // Then
        #expect(authenticationFlow == .wpcom)
    }

    @Test func authenticationFlow_for_site_pages_when_site_has_SSO_enabled() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: true,
                                                              wporgCredentialsAvailable: false)

        // Then
        #expect(authenticationFlow == .jetpackSSO)
    }

    @Test func authenticationFlow_for_site_pages_when_site_has_SSO_disabled() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: false)
        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: true,
                                                              wporgCredentialsAvailable: false)

        // Then
        #expect(authenticationFlow == .none)
    }

    @Test func authenticationFlow_when_user_is_authenticated_with_wporg_crendentials() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: false)
        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: false,
                                                              wporgCredentialsAvailable: true)

        // Then
        #expect(authenticationFlow == .siteCredentials)
    }

    @Test func authenticationFlow_when_user_is_not_authenticated_with_wpcom_or_wporg_crendentials() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: false,
                                                              wporgCredentialsAvailable: false)

        // Then
        #expect(authenticationFlow == .none)
    }

    @Test func isAuthenticationFailure_returns_true_if_first_navigation_fails_with_error_status_code() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let loginURL = try #require(URL(string: siteURL + "/wp-login.php"))
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 404, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .siteCredentials,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == true)
    }

    @Test func isAuthenticationFailure_returns_true_if_first_navigation_url_is_login_page_for_site_credentials() throws {
        // Given
        let loginURL = try #require(URL(string: siteURL + "/wp-login.php"))
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, loginURL: loginURL.absoluteString)
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .siteCredentials,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == true)
    }

    @Test func isAuthenticationFailure_returns_true_if_first_navigation_url_is_login_page_for_wpcom() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let loginURL = WooConstants.URLs.loginWPCom.asURL()
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .wpcom,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == true)
    }

    @Test func isAuthenticationFailure_returns_true_if_first_navigation_url_is_login_page_for_jetpack_sso() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let loginURL = WooConstants.URLs.loginWPCom.asURL()
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .jetpackSSO,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == true)
    }

    @Test func isAuthenticationFailure_returns_true_if_first_navigation_url_is_login_page_when_authentication_flow_is_none() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL)
        let loginURL = WooConstants.URLs.loginWPCom.asURL()
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .none,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == false)
    }

    @Test func isAuthenticationFailure_returns_false_for_first_page_being_non_login_page() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let response = try #require(HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .jetpackSSO,
                                                          isFirstNavigation: true)

        // Then
        #expect(isFailure == false)
    }

    @Test func isAuthenticationFailure_returns_false_for_non_first_navigation() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, url: siteURL, hasSSOEnabled: true)
        let loginURL = WooConstants.URLs.loginWPCom.asURL()
        let response = try #require(HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil))

        let testURL = try #require(URL(string: siteURL + "/products/13"))
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let isFailure = viewModel.isAuthenticationFailure(response: response,
                                                          currentSite: testSite,
                                                          authenticationFlow: .jetpackSSO,
                                                          isFirstNavigation: false)

        // Then
        #expect(isFailure == false)
    }
}
