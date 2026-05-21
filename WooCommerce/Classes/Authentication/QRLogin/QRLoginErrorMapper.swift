import Foundation
import Yosemite

/// Maps `QRLoginNetworkError`s and other Remote-level outcomes into the
/// user-facing variants from spec §8.
///
/// Encodes the protocol + phase rules:
///   - Self-hosted 404 / 426 on scan → "This store can't complete QR login".
///   - WP.com 404 on scan → "Code expired".
///   - WP.com 404 on exchange → "Sign-in interrupted".
///   - 412 on exchange → disambiguated by body code into "Sign-in timed out"
///     (`qr_login_not_approved`) or "Sign-in interrupted"
///     (`invalid_exchange_grant`).
///   - 500 `already_consumed` on wp.com exchange → "Already signed in elsewhere".
///   - 429 anywhere → "Too many attempts".
///   - Transport / 5xx / unmapped → "Couldn't reach your store" /
///     "Something went wrong".
///
/// The mapper is intentionally pure — no I/O, no logging — so it is exhaustively
/// testable against the spec tables.
enum QRLoginErrorMapper {

    enum Protocol_ {
        case selfHosted
        case wpCom
    }

    /// Map a network error from /scan into a user-facing variant.
    static func userFacingError(forScan error: QRLoginNetworkError,
                                protocol_: Protocol_) -> QRLoginUserFacingError {
        switch error {
        case .unauthorized:
            return .init(kind: .codeExpired, phase: .scan, primaryAction: .scanAgain)

        case .notFound:
            switch protocol_ {
            case .selfHosted:
                return .init(kind: .storeUnsupported, phase: .scan, primaryAction: .retryFailedPhase)
            case .wpCom:
                return .init(kind: .codeExpired, phase: .scan, primaryAction: .scanAgain)
            }

        case .upgradeRequired:
            return .init(kind: .storeUnsupported, phase: .scan, primaryAction: .retryFailedPhase)

        case .conflict:
            return .init(kind: .codeAlreadyUsed, phase: .scan, primaryAction: .scanAgain)

        case .rateLimited:
            return .init(kind: .rateLimited, phase: .scan, primaryAction: .retryFailedPhase)

        case .network:
            return .init(kind: .network, phase: .scan, primaryAction: .retryFailedPhase)

        case .badRequest, .clientError, .preconditionFailed, .internalServerError, .serverError, .malformed:
            return .init(kind: .unexpected, phase: .scan, primaryAction: .retryFailedPhase)
        }
    }

    /// Map a network error from /session-status into a user-facing variant.
    /// Returns `nil` for transient errors that should be absorbed by the
    /// 4-strike threshold — the caller decides when to surface them.
    ///
    /// Note: wp.com's poll 404 is handled inside `WPComQRLoginRemote` (it is
    /// coerced to a `.expired` session status, not surfaced as an error).
    static func userFacingError(forPoll error: QRLoginNetworkError,
                                protocol_: Protocol_) -> QRLoginUserFacingError? {
        switch error {
        case .notFound:
            // Self-hosted poll 404 is terminal (the merchant's WC plugin
            // doesn't expose the endpoint).
            return .init(kind: .storeUnsupported, phase: .poll, primaryAction: .retryFailedPhase)

        case .rateLimited:
            // 429 is terminal for both protocols.
            return .init(kind: .rateLimited, phase: .poll, primaryAction: .retryFailedPhase)

        case .unauthorized:
            // WP.com poll 403 = token_hash mismatch; treat the token as
            // compromised, require a fresh scan.
            return .init(kind: .codeExpired, phase: .poll, primaryAction: .scanAgain)

        case .network, .badRequest, .clientError, .preconditionFailed,
             .internalServerError, .serverError, .malformed, .upgradeRequired, .conflict:
            return nil // transient — handled by the polling loop's 4-strike budget
        }
    }

    /// Used after the 4-strike threshold has fired — converts a transient
    /// network error into the final user-facing variant.
    static func userFacingError(forPollAfterThreshold error: QRLoginNetworkError) -> QRLoginUserFacingError {
        switch error {
        case .network:
            return .init(kind: .network, phase: .poll, primaryAction: .retryFailedPhase)
        default:
            return .init(kind: .unexpected, phase: .poll, primaryAction: .retryFailedPhase)
        }
    }

    /// Map a terminal poll *state* into a user-facing variant.
    static func userFacingError(forTerminalState state: QRLoginSessionState,
                                protocol_: Protocol_) -> QRLoginUserFacingError? {
        switch state {
        case .rejected:
            return .init(kind: .signInDenied, phase: .poll, primaryAction: .scanAgain)
        case .expired, .unknown:
            return .init(kind: .signInTimedOut, phase: .poll, primaryAction: .scanAgain)
        case .consumed:
            return .init(kind: .alreadySignedInElsewhere, phase: .poll, primaryAction: .scanAgain)
        case .approved, .scanned:
            return nil // not terminal
        }
    }

    /// Map a network error from /exchange into a user-facing variant.
    static func userFacingError(forExchange error: QRLoginNetworkError,
                                protocol_: Protocol_) -> QRLoginUserFacingError {
        switch error {
        case .unauthorized:
            return .init(kind: .codeExpired, phase: .exchange, primaryAction: .scanAgain)

        case .notFound:
            switch protocol_ {
            case .selfHosted:
                return .init(kind: .storeUnsupported, phase: .exchange, primaryAction: .retryFailedPhase)
            case .wpCom:
                return .init(kind: .signInInterrupted, phase: .exchange, primaryAction: .scanAgain)
            }

        case .rateLimited:
            return .init(kind: .rateLimited, phase: .exchange, primaryAction: .retryFailedPhase)

        case .preconditionFailed(let code):
            switch code {
            case "qr_login_not_approved":
                return .init(kind: .signInTimedOut, phase: .exchange, primaryAction: .scanAgain)
            case "invalid_exchange_grant":
                return .init(kind: .signInInterrupted, phase: .exchange, primaryAction: .scanAgain)
            default:
                return .init(kind: .unexpected, phase: .exchange, primaryAction: .retryFailedPhase)
            }

        case .internalServerError(let code):
            switch code {
            case "already_consumed" where protocol_ == .wpCom:
                return .init(kind: .alreadySignedInElsewhere, phase: .exchange, primaryAction: .scanAgain)
            default:
                return .init(kind: .unexpected, phase: .exchange, primaryAction: .retryFailedPhase)
            }

        case .network:
            return .init(kind: .network, phase: .exchange, primaryAction: .retryFailedPhase)

        case .badRequest, .clientError, .conflict, .upgradeRequired, .serverError, .malformed:
            return .init(kind: .unexpected, phase: .exchange, primaryAction: .retryFailedPhase)
        }
    }
}
