import Foundation
import Testing
@testable import WooCommerce

struct QRLoginPayloadParserTests {

    private let parser = QRLoginPayloadParser()

    // MARK: - Magic-link (§3.1)

    @Test func parse_when_magic_link_with_scheme_woocommerce_then_returns_magicLink() {
        // Given
        let input = "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token=abc123"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .magicLink(url: URL(string: input)!))
    }

    @Test func parse_when_magic_link_with_scheme_wordpress_then_returns_invalid() {
        // Given — wp-app QR; must NOT silently launch here.
        let input = "https://wordpress.com/wp-login.php?action=magic-login&scheme=wordpress&token=abc123"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_magic_link_with_blank_token_then_returns_invalid() {
        // Given
        let input = "https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token="

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_magic_link_with_wrong_action_then_returns_invalid() {
        // Given
        let input = "https://wordpress.com/wp-login.php?action=login&scheme=woocommerce&token=abc"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    // MARK: - Install QR (§3.2)

    @Test func parse_when_install_qr_then_returns_installQR() {
        // Given
        let input = "https://woocommerce.com/mobile/?utm_source=onboarding"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .installQR)
    }

    @Test func parse_when_woo_com_url_without_mobile_segment_then_returns_invalid() {
        // Given
        let input = "https://woocommerce.com/blog/"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    // MARK: - Legacy app-login (§3.3 / §10.3)

    @Test func parse_when_app_login_with_wpcom_email_then_takes_precedence_over_username() {
        // Given — `wpcomEmail` takes precedence over `username`.
        let input = "woocommerce://app-login?siteUrl=https://example.com&wpcomEmail=user@example.com&username=user"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .appLoginWPCom(siteURL: "https://example.com", email: "user@example.com"))
    }

    @Test func parse_when_app_login_with_only_username_then_returns_appLoginUsername() {
        // Given
        let input = "woocommerce://app-login?siteUrl=http://example.com&username=user"

        // When
        let payload = parser.parse(input)

        // Then — http acceptable for legacy app-login per §10.3.
        #expect(payload == .appLoginUsername(siteURL: "http://example.com", username: "user"))
    }

    @Test func parse_when_app_login_missing_siteUrl_then_returns_invalid() {
        // Given
        let input = "woocommerce://app-login?username=user"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_app_login_with_userinfo_in_siteUrl_then_returns_invalid() {
        // Given
        let input = "woocommerce://app-login?siteUrl=https://u:p@example.com&username=user"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    // MARK: - Self-hosted QR (§3.4)

    @Test func parse_when_self_hosted_qr_with_valid_token_then_returns_selfHosted() {
        // Given
        let token = String(repeating: "a", count: 64)
        let input = "woocommerce://qr-login?token=\(token)&siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .selfHosted(token: token, siteURL: URL(string: "https://example.com")!))
    }

    @Test func parse_when_self_hosted_qr_with_short_token_then_returns_invalid() {
        // Given — 63 chars, just below the 64-character minimum.
        let token = String(repeating: "a", count: 63)
        let input = "woocommerce://qr-login?token=\(token)&siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_self_hosted_qr_with_http_siteUrl_then_rejected_in_release_only() {
        // Given — http siteUrl. Release builds reject it (the /scan token and
        // /exchange Application Password must not travel in cleartext, §3.4);
        // DEBUG builds accept it so the flow can be tested against a local server.
        let token = String(repeating: "a", count: 64)
        let input = "woocommerce://qr-login?token=\(token)&siteUrl=http://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #if DEBUG
        #expect(payload == .selfHosted(token: token, siteURL: URL(string: "http://example.com")!))
        #else
        #expect(payload == .invalid)
        #endif
    }

    @Test func parse_when_self_hosted_qr_with_query_in_siteUrl_then_returns_invalid() {
        // Given
        let token = String(repeating: "a", count: 64)
        let input = "woocommerce://qr-login?token=\(token)&siteUrl=https://example.com?utm=x"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_self_hosted_qr_normalises_host_to_lowercase_and_strips_trailing_slash() {
        // Given
        let token = String(repeating: "a", count: 64)
        let input = "woocommerce://qr-login?token=\(token)&siteUrl=https://EXAMPLE.com/"

        // When
        let payload = parser.parse(input)

        // Then
        guard case let .selfHosted(_, siteURL) = payload else {
            Issue.record("Expected .selfHosted, got \(payload)")
            return
        }
        #expect(siteURL.absoluteString == "https://example.com")
    }

    // MARK: - Site-URL-only QR (§3.5)

    @Test func parse_when_qr_login_without_token_then_returns_siteURLOnly() {
        // Given
        let input = "woocommerce://qr-login?siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .siteURLOnly(siteURL: URL(string: "https://example.com")!))
    }

    @Test func parse_when_qr_login_with_blank_token_then_returns_siteURLOnly() {
        // Given
        let input = "woocommerce://qr-login?token=&siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .siteURLOnly(siteURL: URL(string: "https://example.com")!))
    }

    // MARK: - WP.com QR (§3.6)

    @Test func parse_when_wpcom_qr_with_valid_compound_token_and_encrypted_then_returns_wpCom() {
        // Given
        let token = "\(String(repeating: "a", count: 64)):\(String(repeating: "b", count: 32))"
        let encrypted = "blob"
        let input = "woocommerce://qr-login?token=\(token)&encrypted=\(encrypted)"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .wpCom(token: token, encrypted: encrypted))
    }

    @Test func parse_when_wpcom_qr_with_malformed_token_then_returns_invalid() {
        // Given — second segment must be 32 hex chars, not 31.
        let token = "\(String(repeating: "a", count: 64)):\(String(repeating: "b", count: 31))"
        let input = "woocommerce://qr-login?token=\(token)&encrypted=blob"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_wpcom_qr_missing_encrypted_then_returns_invalid() {
        // Given
        let token = "\(String(repeating: "a", count: 64)):\(String(repeating: "b", count: 32))"
        let input = "woocommerce://qr-login?token=\(token)"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_qr_login_has_both_siteUrl_and_encrypted_then_routes_to_self_hosted_branch() {
        // Given — wp.com branch is gated on siteUrl being absent.
        // A compound wp.com-shaped token would fail the self-hosted regex
        // (it contains a `:`), and the self-hosted branch is selected. Result:
        // .invalid (rejected by the self-hosted token check).
        let token = "\(String(repeating: "a", count: 64)):\(String(repeating: "b", count: 32))"
        let input = "woocommerce://qr-login?token=\(token)&encrypted=blob&siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    // MARK: - Custom-scheme case insensitivity (§3 footer)

    @Test func parse_when_scheme_and_host_are_uppercase_then_still_matches() {
        // Given
        let token = String(repeating: "a", count: 64)
        let input = "WOOCOMMERCE://QR-LOGIN?token=\(token)&siteUrl=https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .selfHosted(token: token, siteURL: URL(string: "https://example.com")!))
    }

    // MARK: - Invalid

    @Test func parse_when_input_is_unrelated_url_then_returns_invalid() {
        // Given
        let input = "https://example.com"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }

    @Test func parse_when_input_is_garbage_then_returns_invalid() {
        // Given
        let input = "not a url"

        // When
        let payload = parser.parse(input)

        // Then
        #expect(payload == .invalid)
    }
}
