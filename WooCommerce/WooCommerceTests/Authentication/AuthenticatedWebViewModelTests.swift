import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct AuthenticatedWebViewModelTests {

    private static let testURLs = [
        URL(string: "https://wordpress.com/jetpack/connect?url=%@&mobile_redirect=%@&from=mobile"),
        URL(string: "https://jetpack.wordpress.com/jetpack.authorize"),
        URL(string: "https://woocommerce.com/products/product-bundles/"),
        URL(string: "https://jetpack.com/stats/")
    ]
    private let siteURL = "http://example.com"

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

    @Test func makeJetpackSSOLoginURL_includes_redirect_to_with_full_initial_url() throws {
        // Given
        let initialURL = try #require(URL(string: siteURL + "/wp-admin/admin.php?page=wc-settings&tab=point-of-sale&section=staff"))

        // When
        let loginURL = try #require(AuthenticatedWebViewController.makeJetpackSSOLoginURL(
            from: siteURL + "/wp-login.php?foo=bar",
            redirectingTo: initialURL
        ))
        let components = try #require(URLComponents(url: loginURL, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []

        // Then
        #expect(components.scheme == "http")
        #expect(components.host == "example.com")
        #expect(components.path == "/wp-login.php")
        #expect(queryItems.first(where: { $0.name == "foo" })?.value == "bar")
        #expect(queryItems.first(where: { $0.name == "action" })?.value == "jetpack-sso")
        #expect(queryItems.first(where: { $0.name == "redirect_to" })?.value == initialURL.absoluteString)
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
