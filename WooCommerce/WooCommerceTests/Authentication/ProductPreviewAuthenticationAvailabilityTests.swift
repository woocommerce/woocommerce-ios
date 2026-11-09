import Foundation
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct ProductPreviewAuthenticationAvailabilityTests {
    @Test func test_canAuthenticate_when_wpcom_credentials_and_site_SSO_are_available_then_returns_true() throws {
        // Given
        let sessionManager = MockSessionManager()
        sessionManager.defaultSite = Site.fake().copy(url: "https://example.com", hasSSOEnabled: true)
        sessionManager.defaultCredentials = .wpcom(username: "merchant",
                                                   authToken: "token",
                                                   siteAddress: "https://example.com")
        let availability = ProductPreviewAuthenticationAvailability(sessionManager: sessionManager)
        let url = try #require(URL(string: "https://example.com/product"))

        // When
        let canAuthenticate = availability.canAuthenticate(for: url)

        // Then
        #expect(canAuthenticate)
    }

    @Test func test_canAuthenticate_when_site_username_and_password_are_available_then_returns_true() throws {
        // Given
        let sessionManager = MockSessionManager()
        sessionManager.defaultSite = Site.fake().copy(url: "https://example.com", hasSSOEnabled: false)
        sessionManager.defaultCredentials = .wporg(username: "merchant",
                                                   password: "password",
                                                   siteAddress: "https://example.com")
        let availability = ProductPreviewAuthenticationAvailability(sessionManager: sessionManager)
        let url = try #require(URL(string: "https://example.com/product"))

        // When
        let canAuthenticate = availability.canAuthenticate(for: url)

        // Then
        #expect(canAuthenticate)
    }

    @Test func test_canAuthenticate_when_application_password_is_available_then_returns_false() throws {
        // Given
        let sessionManager = MockSessionManager()
        sessionManager.defaultSite = Site.fake().copy(url: "https://example.com", hasSSOEnabled: true)
        sessionManager.defaultCredentials = .applicationPassword(username: "merchant",
                                                                 password: "password",
                                                                 siteAddress: "https://example.com")
        let availability = ProductPreviewAuthenticationAvailability(sessionManager: sessionManager)
        let url = try #require(URL(string: "https://example.com/product"))

        // When
        let canAuthenticate = availability.canAuthenticate(for: url)

        // Then
        #expect(!canAuthenticate)
    }
}
