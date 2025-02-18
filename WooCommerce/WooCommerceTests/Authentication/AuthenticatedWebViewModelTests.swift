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
        let unwrappedURL = try #require(initialURL, "Initial URL should not be nil")
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
        let testURL = try #require(URL(string: siteURL + "/products/13"), "Test URL should not be nil")
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
        let testURL = try #require(URL(string: siteURL + "/products/13"), "Test URL should not be nil")
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
        let testURL = try #require(URL(string: siteURL + "/products/13"), "Test URL should not be nil")
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
        let testURL = try #require(URL(string: siteURL + "/products/13"), "Test URL should not be nil")
        let viewModel = DefaultAuthenticatedWebViewModel(initialURL: testURL)

        // When
        let authenticationFlow = viewModel.authenticationFlow(currentSite: testSite,
                                                              wpcomCredentialsAvailable: false,
                                                              wporgCredentialsAvailable: false)

        // Then
        #expect(authenticationFlow == .none)
    }
}
