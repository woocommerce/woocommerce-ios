import Foundation

/// Subtitle to display on the number-match screen. Per spec §4.3, the
/// self-hosted flow shows the site host and the wp.com flow shows the user's
/// wp.com email returned by `/scan`.
enum QRLoginNumberMatchSubtitle: Equatable {
    case host(String)
    case email(String)
}

/// Outcome of the `/scan` step exposed to the view model. Protocol-agnostic so
/// the view model doesn't care whether it came from `wc-admin` or `wp.com`.
struct QRLoginScanResult: Equatable {
    let sessionID: String
    let realNumber: String
    let expiresInSeconds: Int
    /// Hash of the QR token sent on every poll. Recomputed by the strategy
    /// once at scan time and reused for the lifetime of the session.
    let tokenHash: String
    /// Subtitle to display on the number-match screen.
    let subtitle: QRLoginNumberMatchSubtitle
}

/// Outcome of a successful `/exchange` step. The two protocols finish a
/// sign-in very differently, so the view model needs to tell them apart:
///   - `authenticated`: the self-hosted flow has fully signed the merchant in
///     (AP minted + persisted, eligibility checked) — the app can proceed to
///     the store picker.
///   - `magicLinkHandedOff`: the wp.com flow has handed a magic link to an
///     in-app browser. Sign-in completes asynchronously via the existing
///     `woocommerce://magic-login` redirect handler, NOT here — so the QR-login
///     surface must not route to the store picker itself (spec §10.1).
enum QRLoginExchangeOutcome: Equatable {
    case authenticated
    case magicLinkHandedOff
}

/// Protocol-specific façade for the QR-login flow.
///
/// Holds enough state (token, encrypted blob, siteURL, sessionID, grant) to
/// run scan / poll / exchange + post-success against either the self-hosted
/// or wp.com endpoints. The view model drives the state machine and asks the
/// strategy to execute each phase.
///
/// The strategy carries protocol identity (`protocol_`) so the view model can
/// pick the right entry in the error-mapping tables. `numberMatchSubtitle`
/// returns the live subtitle for the number-match UI (the wp.com value is
/// only known after `/scan` returns).
@MainActor
protocol QRLoginStrategy: AnyObject {
    var protocol_: QRLoginErrorMapper.Protocol_ { get }

    /// Run `/scan`. Stores the returned session ID + grant internally for
    /// the subsequent poll / exchange.
    func scan() async -> Result<QRLoginScanResult, QRLoginUserFacingError>

    /// Returns a `PollAttempt` that runs `/session-status` once. The view
    /// model hands it to `QRLoginPollingLoop`.
    func makePollAttempt() -> QRLoginPollingLoop.PollAttempt

    /// Run `/exchange` and the protocol-specific post-success work
    /// (self-hosted: site fetch + AP save + eligibility; wp.com: open the
    /// magic-link URL). The outcome tells the view model whether sign-in is
    /// complete or has been handed off to an in-app browser.
    func exchange(grant: String) async -> Result<QRLoginExchangeOutcome, QRLoginUserFacingError>
}
