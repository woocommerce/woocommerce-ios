import Foundation
import Testing
import UIKit
import WordPressAuthenticator
@testable import WooCommerce

/// Tests for the QR-login wiring in `AuthenticationManager` — the deep-link
/// availability gates and the signed-in session-replace entry point that PR
/// 7/7 added.
///
/// The flows are driven through the public `handleAuthenticationUrl` and
/// `handleSignedInQRLoginDeepLink` methods. `displayAuthenticatorIfLoggedOut`
/// is stubbed to a standalone navigation controller (no window) so the deep-link
/// coordinator can push its host view without kicking off the live SwiftUI flow.
@Suite(.timeLimit(.minutes(1)))
@MainActor
struct AuthenticationManagerQRLoginTests {

    init() {
        WordPressAuthenticator.initializeAuthenticator()
    }

    // MARK: - handleSignedInQRLoginDeepLink

    @Test func handleSignedInQRLoginDeepLink_when_not_a_qr_url_then_returns_false() async {
        // Given — a non-QR deep link. Availability is on to prove the URL check
        // is what rejects it.
        let manager = makeManager(deepLinkAvailable: true)
        let url = URL(string: "woocommerce://app-login?siteUrl=https://example.com&username=demo")!

        // When
        let handled = await manager.handleSignedInQRLoginDeepLink(url, rootViewController: UIViewController())

        // Then
        #expect(handled == false)
    }

    @Test func handleSignedInQRLoginDeepLink_when_qr_url_but_unavailable_then_returns_false() async {
        // Given — a QR deep link but the feature flag is off.
        let manager = makeManager(deepLinkAvailable: false)

        // When
        let handled = await manager.handleSignedInQRLoginDeepLink(Self.selfHostedURL, rootViewController: UIViewController())

        // Then
        #expect(handled == false)
    }

    @Test func handleSignedInQRLoginDeepLink_when_qr_url_and_available_then_takes_over() async {
        // Given — a QR deep link with the feature available.
        let manager = makeManager(deepLinkAvailable: true)

        // When
        let handled = await manager.handleSignedInQRLoginDeepLink(Self.selfHostedURL, rootViewController: UIViewController())

        // Then — the manager took over to present the session-replace warning.
        #expect(handled == true)
    }

    // MARK: - handleAuthenticationUrl (logged-out QR deep link)

    @Test func handleAuthenticationUrl_when_qr_url_but_unavailable_then_does_not_take_over() async {
        // Given — a QR deep link with the flag off; it must fall through rather
        // than being handled.
        let manager = makeManager(deepLinkAvailable: false)
        manager.displayAuthenticatorIfLoggedOut = { UINavigationController() }

        // When
        let handled = await manager.handleAuthenticationUrl(Self.selfHostedURL,
                                                            options: [:],
                                                            rootViewController: UIViewController())

        // Then — `handleQRLoginUrl` returns nil, the QR branch is skipped, and
        // no handler claims the URL.
        #expect(handled == false)
    }

    @Test func handleAuthenticationUrl_when_qr_url_available_and_logged_out_then_starts_deeplink_flow() async {
        // Given — a QR deep link with the feature available and a logged-out
        // authenticator stack to push onto.
        let manager = makeManager(deepLinkAvailable: true)
        let deepLinkNav = UINavigationController()
        manager.displayAuthenticatorIfLoggedOut = { deepLinkNav }

        // When
        let handled = await manager.handleAuthenticationUrl(Self.selfHostedURL,
                                                            options: [:],
                                                            rootViewController: UIViewController())

        // Then — the manager took over and the deep-link coordinator pushed its
        // live-flow host view onto the authenticator stack.
        #expect(handled == true)
        #expect(deepLinkNav.viewControllers.count == 1)
    }

    @Test func handleAuthenticationUrl_when_qr_url_available_but_no_authenticator_then_returns_false() async {
        // Given — the feature is available but there is no logged-out UI to
        // display the flow on.
        let manager = makeManager(deepLinkAvailable: true)
        manager.displayAuthenticatorIfLoggedOut = { nil }

        // When
        let handled = await manager.handleAuthenticationUrl(Self.selfHostedURL,
                                                            options: [:],
                                                            rootViewController: UIViewController())

        // Then
        #expect(handled == false)
    }
}

// MARK: - Helpers

private extension AuthenticationManagerQRLoginTests {

    /// A valid self-hosted QR deep link — 64-char token + https site URL — so
    /// the internal parser yields `.selfHosted`, which pushes a plain host view
    /// (no storyboard) when routed.
    static let selfHostedURL: URL = {
        let token = String(repeating: "a", count: 64)
        return URL(string: "woocommerce://qr-login?token=\(token)&siteUrl=https://example.com")!
    }()

    func makeManager(deepLinkAvailable: Bool) -> AuthenticationManager {
        AuthenticationManager(
            qrLoginAvailability: MockQRLoginAvailability(deepLinkAvailable: deepLinkAvailable)
        )
    }
}

@MainActor
private final class MockQRLoginAvailability: QRLoginAvailabilityProvider {
    var prologueAvailable: Bool
    var deepLinkAvailable: Bool

    init(prologueAvailable: Bool = false, deepLinkAvailable: Bool = false) {
        self.prologueAvailable = prologueAvailable
        self.deepLinkAvailable = deepLinkAvailable
    }

    func isAvailableForPrologue() async -> Bool { prologueAvailable }
    func isAvailableForDeepLink() async -> Bool { deepLinkAvailable }
}
