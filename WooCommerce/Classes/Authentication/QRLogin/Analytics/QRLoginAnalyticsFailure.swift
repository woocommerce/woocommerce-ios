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
}
