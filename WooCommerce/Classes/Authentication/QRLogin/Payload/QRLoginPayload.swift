import Foundation

/// Parsed result of a QR-login input string (camera scan or inbound deep link).
///
/// The variants and their precedence are defined in the QR-login spec §3 — the matching
/// is order-sensitive and the first matching variant wins.
enum QRLoginPayload: Equatable {
    /// `https://wordpress.com/wp-login.php?action=magic-login&scheme=woocommerce&token=...`
    ///
    /// The `scheme=woocommerce` parameter is load-bearing — a QR carrying
    /// `scheme=wordpress` is intended for the WordPress app and must not be
    /// silently launched here.
    case magicLink(url: URL)

    /// Install QR from wp-admin onboarding: `https://woocommerce.com/mobile/...`.
    ///
    /// The app is already installed — there is nothing useful to do with this
    /// payload other than tell the user.
    case installQR

    /// `woocommerce://app-login?siteUrl=...&wpcomEmail=...` — legacy app-login
    /// payload that pre-fills the WP.com email + password screen.
    case appLoginWPCom(siteURL: String, email: String)

    /// `woocommerce://app-login?siteUrl=...&username=...` — legacy app-login
    /// payload that pre-fills the self-hosted site-credentials screen.
    case appLoginUsername(siteURL: String, username: String)

    /// `woocommerce://qr-login?token=...&siteUrl=...` — self-hosted QR-login
    /// payload. `siteUrl` is https-only and normalised; `token` matches
    /// `^[A-Za-z0-9]{64,512}$`.
    case selfHosted(token: String, siteURL: URL)

    /// `woocommerce://qr-login?siteUrl=...` (no token, or blank token) — used
    /// to pre-fill the site-address login screen, which auto-submits on entry.
    case siteURLOnly(siteURL: URL)

    /// `woocommerce://qr-login?token=...&encrypted=...` (no `siteUrl`) — WP.com
    /// QR-login payload. `token` is the compound `{64-hex}:{32-hex}` server
    /// handle; `encrypted` is a non-blank Base64-URL AEAD blob.
    case wpCom(token: String, encrypted: String)

    /// Input didn't match any of the recognised payloads.
    case invalid
}
