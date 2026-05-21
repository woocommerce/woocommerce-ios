import Foundation

/// Maps an HTTP status code (+ optional body) into a `QRLoginNetworkError`.
///
/// The mapping is shared across the three QR-login phases (scan / poll /
/// exchange) and across both protocols (self-hosted / wp.com). Protocol- and
/// phase-specific *user-facing* mapping (e.g. self-hosted 404 → "This store
/// can't complete QR login", wp.com 404 on poll → coerced-to-expired) happens
/// one layer up, in `QRLoginErrorMapper`. This helper only deals in the
/// network-level vocabulary.
enum QRLoginHTTPStatusMapper {

    /// Returns `nil` for 2xx responses (no error). Otherwise returns the
    /// matching `QRLoginNetworkError`.
    static func error(forStatusCode statusCode: Int, body: Data) -> QRLoginNetworkError? {
        if (200..<300).contains(statusCode) {
            return nil
        }
        let code = QRLoginResponseBody.errorCode(in: body)
        switch statusCode {
        case 400:
            return .badRequest(code: code)
        case 401, 403:
            return .unauthorized
        case 404:
            return .notFound
        case 409:
            return .conflict
        case 412:
            return .preconditionFailed(code: code)
        case 426:
            return .upgradeRequired
        case 429:
            return .rateLimited
        case 500:
            return .internalServerError(code: code)
        case 501..<600:
            return .serverError(status: statusCode)
        default:
            return .clientError(status: statusCode)
        }
    }
}
