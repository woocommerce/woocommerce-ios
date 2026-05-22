import Foundation

/// Formats the `failure` property of a `UNIFIED_LOGIN_FAILURE` event for the
/// QR-login flow, per spec §9.3.
///
/// The common shape is `<reason>:<phase>`. Payload / scanner failures (raised
/// before any flow starts) emit the reason alone, and session-replace logout
/// failure has its own dedicated value. Keeping these as compile-time-safe
/// values prevents the analytics strings from drifting between iOS and
/// Android.
struct QRLoginAnalyticsFailure {

    enum Reason: String {
        case network = "Network"
        case rateLimited = "RateLimited"
        case serverError = "ServerError"
        case unknown = "Unknown"
        case endpointMissing = "EndpointMissing"
        case tokenRejected = "TokenRejected"
        case matchTimedOut = "MatchTimedOut"
        case matchRejected = "MatchRejected"
        case matchAlreadyScanned = "MatchAlreadyScanned"
        case matchInvalidGrant = "MatchInvalidGrant"
        case matchAlreadyCompleted = "MatchAlreadyCompleted"
        case notAWooSite = "NotAWooSite"
        case userNotEligible = "UserNotEligible"
        case siteAuthFailure = "SiteAuthFailure"
    }

    enum Phase: String {
        case scan = "Scan"
        case poll = "Poll"
        case approve = "Approve"
        case exchange = "Exchange"
        case auth = "Auth"
    }

    /// Standard `<reason>:<phase>` failures.
    static func reason(_ reason: Reason, phase: Phase) -> String {
        "\(reason.rawValue):\(phase.rawValue)"
    }

    /// Payload / scanner failures fired before any flow starts. No phase suffix.
    static let invalidPayload = "InvalidPayload"
    static let scanner = "Scanner"
    static let installQrCode = "InstallQrCode"

    /// Session-replace logout failure (§9.3 exception).
    static let sessionReplaceLogoutFailed = "Network:session_replace_logout_failed"

    /// Maps a user-facing error to the §9.3 failure string. Centralised so the
    /// iOS and Android emissions stay byte-identical.
    static func failureString(for error: QRLoginUserFacingError) -> String {
        let phase: Phase
        switch error.phase {
        case .scan: phase = .scan
        case .poll: phase = .poll
        case .exchange: phase = .exchange
        case .postExchange: phase = .auth
        case .prelude:
            // Payload / scanner failures never have a phase suffix.
            switch error.kind {
            case .invalidPayload: return invalidPayload
            case .scannerFailure: return scanner
            case .installQR: return installQrCode
            default: return invalidPayload
            }
        }

        let reason: Reason
        switch error.kind {
        case .network: reason = .network
        case .rateLimited: reason = .rateLimited
        case .unexpected: reason = .serverError
        case .storeUnsupported: reason = .endpointMissing
        case .codeExpired: reason = .tokenRejected
        case .signInTimedOut: reason = .matchTimedOut
        case .signInDenied: reason = .matchRejected
        case .codeAlreadyUsed: reason = .matchAlreadyScanned
        case .signInInterrupted: reason = .matchInvalidGrant
        case .alreadySignedInElsewhere: reason = .matchAlreadyCompleted
        case .notAWooSite: reason = .notAWooSite
        case .userNotEligible: reason = .userNotEligible
        case .siteAuthFailure: reason = .siteAuthFailure
        case .invalidPayload, .installQR, .scannerFailure: reason = .unknown
        }

        return Self.reason(reason, phase: phase)
    }
}
