import Foundation

/// Errors emitted by the QR-login `Remote`s. Captures just enough HTTP detail
/// to drive the user-facing error mapping in spec §5.1 / §5.2 / §8.
///
/// The user-facing variant lives one layer up (`QRLoginErrorMapper`); this
/// type is intentionally protocol-agnostic so the same value works for both
/// self-hosted and wp.com responses.
public enum QRLoginNetworkError: Error, Equatable {
    /// HTTP 401 or 403 with no special body code.
    case unauthorized
    /// HTTP 404 — the merchant's WC plugin doesn't expose QR-login endpoints
    /// (self-hosted), or a wp.com QR expired before reaching the server.
    case notFound
    /// HTTP 426 — "upgrade required". Self-hosted only.
    case upgradeRequired
    /// HTTP 409 — another device already scanned this QR.
    case conflict
    /// HTTP 429 — rate-limited.
    case rateLimited

    /// HTTP 412 (precondition failed) — `body.code` disambiguates between
    /// `qr_login_not_approved`, `invalid_exchange_grant`, etc.
    case preconditionFailed(code: String?)

    /// HTTP 500 — `body.code` disambiguates wp.com's `already_consumed` from
    /// generic failures.
    case internalServerError(code: String?)

    /// Any other 5xx response.
    case serverError(status: Int)

    /// HTTP 400 — `body.code` disambiguates wp.com's `no_number_matching`
    /// from generic bad-request failures.
    case badRequest(code: String?)

    /// Any other 4xx response we didn't pattern-match above.
    case clientError(status: Int)

    /// Transport failure — DNS, socket, timeout, SSL.
    case network

    /// Response body wasn't parseable as the expected shape (missing required
    /// fields, malformed JSON, unexpected types). Treated like an
    /// unmapped-server error for UI purposes.
    case malformed
}
