import Foundation
import Observation
import WordPressAuthenticator

/// Drives the QR-login flow once the user has scanned a self-hosted or wp.com
/// payload. Owns the state machine — the UI layer just observes `state` and
/// renders accordingly.
///
/// State transitions:
///
///   idle ─start()→ authenticating ─/scan ok→ numberMatch ─poll terminal approved→ authenticating ─/exchange ok→ done
///                                                       ↘ poll terminal !approved | transient × 4 → error
///        ↘ scan fails → error
///
/// `/exchange` resolves to `done` for the self-hosted flow (the merchant is
/// fully signed in) or `handedOff` for wp.com (the magic link was opened in an
/// in-app browser; sign-in completes via the magic-login redirect, not here).
///
/// Retry semantics (spec §6.1):
///   - error during scan   → retry runs scan again.
///   - error during poll   → retry resumes polling (same session_id + token_hash).
///   - error during exchange → retry runs exchange again with the retained grant.
///   - non-retryable error → primary CTA is "Scan a new code" — surfaced via
///     `error.primaryAction == .scanAgain`. The coordinator handles that case
///     by sending the user back to the scanner; the view model just reports it.
@MainActor
@Observable
final class QRLoginViewModel {

    enum State: Equatable {
        case idle
        case authenticating
        case numberMatch(scan: QRLoginScanResult)
        /// Self-hosted sign-in completed — the app can proceed to the store picker.
        case done
        /// wp.com magic link handed to an in-app browser — sign-in completes
        /// asynchronously via the magic-login redirect, so the QR-login surface
        /// must not route to the store picker itself (spec §10.1).
        case handedOff
        case error(QRLoginUserFacingError)
    }

    private(set) var state: State = .idle

    /// Subtitle for the number-match screen. Convenience derived from `state`
    /// to keep the SwiftUI binding terse.
    var numberMatchSubtitle: QRLoginNumberMatchSubtitle? {
        if case let .numberMatch(scan) = state {
            return scan.subtitle
        }
        return nil
    }

    private let strategy: QRLoginStrategy
    private let analytics: QRLoginAnalyticsTracking
    private let pollIntervalSeconds: TimeInterval

    /// Tracks the live polling task so cancel from number-match can interrupt
    /// it without making a server call (spec §6.2).
    private var pollingTask: Task<Void, Never>?

    /// Last successful scan; held so a poll-retry resumes against the same
    /// session.
    private var lastScan: QRLoginScanResult?

    /// Last approved grant; held so an exchange-retry doesn't re-run scan or
    /// poll.
    private var lastGrant: String?

    init(strategy: QRLoginStrategy,
         analytics: QRLoginAnalyticsTracking? = nil,
         pollIntervalSeconds: TimeInterval = 2.0) {
        self.strategy = strategy
        // `DefaultQRLoginAnalyticsTracking()` is @MainActor-isolated, so it
        // can't be a default parameter expression (those are evaluated in
        // the caller's context). The view model is @MainActor so constructing
        // it in the body is fine.
        let analytics = analytics ?? DefaultQRLoginAnalyticsTracking()
        self.analytics = analytics
        self.pollIntervalSeconds = pollIntervalSeconds

        analytics.setFlow(.loginQR)
    }

    /// Kicks the flow off from `idle`. Idempotent — calling `start()` while
    /// already running is a no-op.
    func start() async {
        guard state == .idle || isErrorState else { return }
        await runScan()
    }

    /// Re-runs the failed phase per spec §6.1.
    func retry() async {
        guard case .error(let error) = state else { return }
        analytics.trackClick(.qrRetry)

        switch error.phase {
        case .scan, .prelude:
            await runScan()
        case .poll:
            guard let lastScan else {
                await runScan()
                return
            }
            await runPolling(scan: lastScan)
        case .exchange, .postExchange:
            guard let lastGrant else {
                await runScan()
                return
            }
            await runExchange(grant: lastGrant)
        }
    }

    /// Cancel from number-match (spec §6.2). Stops client-side polling and
    /// returns to idle — **no server call**. The server keeps the session in
    /// `scanned` until its 90-second window elapses; the matching browser
    /// polls itself into the "denied" terminal state.
    func cancelFromNumberMatch() {
        guard case .numberMatch = state else { return }
        analytics.trackClick(.qrCancelNumberMatch)
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
    }
}

// MARK: - Internal pipeline

private extension QRLoginViewModel {

    var isErrorState: Bool {
        if case .error = state { return true }
        return false
    }

    func runScan() async {
        setAuthenticatingIfNeeded()
        let result = await strategy.scan()
        switch result {
        case .success(let scan):
            lastScan = scan
            state = .numberMatch(scan: scan)
            analytics.trackStep(.qrNumberMatch)
            await runPolling(scan: scan)
        case .failure(let error):
            surface(error: error)
        }
    }

    func runPolling(scan: QRLoginScanResult) async {
        // Resume number-match presentation when retrying poll.
        if state != .numberMatch(scan: scan) {
            state = .numberMatch(scan: scan)
            analytics.trackStep(.qrNumberMatch)
        }

        let loop = QRLoginPollingLoop(
            protocol_: strategy.protocol_,
            pollInterval: pollIntervalSeconds,
            attempt: strategy.makePollAttempt()
        )

        pollingTask = Task { [weak self] in
            let outcome = await loop.run()
            await self?.handlePollingOutcome(outcome)
        }
        // Wait for completion so callers (`retry`) see the final state.
        await pollingTask?.value
        pollingTask = nil
    }

    func handlePollingOutcome(_ outcome: QRLoginPollingLoop.Outcome) async {
        switch outcome {
        case .approved(let grant):
            lastGrant = grant
            await runExchange(grant: grant)
        case .error(let error):
            surface(error: error)
        case .cancelled:
            // Cancel from number-match already reset state to idle.
            if case .numberMatch = state {
                state = .idle
            }
        }
    }

    func runExchange(grant: String) async {
        setAuthenticatingIfNeeded()
        switch await strategy.exchange(grant: grant) {
        case .success(.authenticated):
            state = .done
        case .success(.magicLinkHandedOff):
            state = .handedOff
        case .failure(let error):
            surface(error: error)
        }
    }

    func setAuthenticatingIfNeeded() {
        if state != .authenticating {
            state = .authenticating
            analytics.trackStep(.qrAuthenticating)
        }
    }

    func surface(error: QRLoginUserFacingError) {
        state = .error(error)
        analytics.trackStep(.qrError)
        analytics.trackFailure(QRLoginAnalyticsFailure.failureString(for: error))
    }
}
