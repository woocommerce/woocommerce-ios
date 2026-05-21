import Foundation
import Networking
import Testing
import WordPressAuthenticator
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct QRLoginViewModelTests {

    // MARK: - Happy path

    @Test func start_when_scan_then_poll_approved_then_exchange_then_state_is_done() async {
        // Given
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = [
            .success(.scanned),
            .success(.approved(exchangeGrant: "grant-1"))
        ]
        strategy.exchangeResult = .success(.authenticated)
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)

        // When
        await viewModel.start()

        // Then
        #expect(viewModel.state == .done)
        #expect(strategy.scanCount == 1)
        #expect(strategy.exchangeCalls == ["grant-1"])
    }

    @Test func start_when_exchange_hands_off_magic_link_then_state_is_handedOff() async {
        // Given — the wp.com exchange opens a magic link in an in-app browser
        // instead of completing sign-in in-app (spec §10.1).
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = [.success(.approved(exchangeGrant: "grant-1"))]
        strategy.exchangeResult = .success(.magicLinkHandedOff)
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)

        // When
        await viewModel.start()

        // Then — the flow stops at .handedOff, never .done, so the coordinator
        // won't route to the store picker before the magic-login redirect
        // finishes the sign-in.
        #expect(viewModel.state == .handedOff)
        #expect(strategy.exchangeCalls == ["grant-1"])
    }

    // MARK: - Cancel from number-match (spec §6.2)

    @Test func cancelFromNumberMatch_when_polling_then_state_returns_to_idle_without_server_call() async {
        // Given — poll stays in scanned forever; we cancel mid-poll.
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = Array(repeating: .success(.scanned), count: 10)
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)

        // When
        let task = Task { await viewModel.start() }
        await waitForState(viewModel) { state in
            if case .numberMatch = state { return true }
            return false
        }
        viewModel.cancelFromNumberMatch()
        await task.value

        // Then
        #expect(viewModel.state == .idle)
        // Strategy was never asked to exchange — confirms no server call on cancel.
        #expect(strategy.exchangeCalls.isEmpty)
    }

    // MARK: - Retry semantics (spec §6.1)

    @Test func retry_when_scan_failed_then_runs_scan_again() async {
        // Given
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .failure(.init(kind: .network, phase: .scan, primaryAction: .retryFailedPhase))
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)
        await viewModel.start()
        #expect(strategy.scanCount == 1)

        // When — next scan succeeds, then poll approves, then exchange OK.
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = [.success(.approved(exchangeGrant: "g"))]
        strategy.exchangeResult = .success(.authenticated)
        await viewModel.retry()

        // Then
        #expect(viewModel.state == .done)
        #expect(strategy.scanCount == 2)
    }

    @Test func retry_when_exchange_failed_then_does_not_rerun_scan_or_poll() async {
        // Given — initial flow gets us to exchange, which fails.
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = [.success(.approved(exchangeGrant: "grant-x"))]
        strategy.exchangeResult = .failure(.init(kind: .network, phase: .exchange, primaryAction: .retryFailedPhase))
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)
        await viewModel.start()

        // Sanity
        guard case .error = viewModel.state else {
            Issue.record("Expected .error after first run, got \(viewModel.state)")
            return
        }
        #expect(strategy.scanCount == 1)
        #expect(strategy.exchangeCalls == ["grant-x"])

        // When — next exchange succeeds.
        strategy.exchangeResult = .success(.authenticated)
        await viewModel.retry()

        // Then
        #expect(viewModel.state == .done)
        #expect(strategy.scanCount == 1) // scan NOT re-run
        #expect(strategy.exchangeCalls == ["grant-x", "grant-x"]) // exchange re-run with same grant
    }

    @Test func retry_when_poll_transient_storm_then_resumes_polling_without_rerunning_scan() async {
        // Given — 4 transient failures trips the threshold, then we retry and
        // the poll succeeds. Spec §6.1: "Poll retry resumes polling with the
        // same session_id and token_hash — /qr-login-scan is NOT re-run."
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = Array(repeating: .failure(QRLoginNetworkError.network), count: 4)
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: SpyAnalytics(), pollIntervalSeconds: 0)
        await viewModel.start()

        // Sanity — polling-loop budget tripped, view model surfaced an error.
        guard case .error = viewModel.state else {
            Issue.record("Expected .error, got \(viewModel.state)")
            return
        }
        let scansAtErrorTime = strategy.scanCount

        // When
        strategy.pollResults = [.success(.approved(exchangeGrant: "g"))]
        strategy.exchangeResult = .success(.authenticated)
        await viewModel.retry()

        // Then
        #expect(viewModel.state == .done)
        #expect(strategy.scanCount == scansAtErrorTime) // scan NOT re-run on poll retry
    }

    // MARK: - Analytics

    @Test func start_emits_qrAuthenticating_then_qrNumberMatch() async {
        // Given
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .success(makeScanResult())
        strategy.pollResults = [.success(.approved(exchangeGrant: "g"))]
        strategy.exchangeResult = .success(.authenticated)
        let analytics = SpyAnalytics()
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: analytics, pollIntervalSeconds: 0)

        // When
        await viewModel.start()

        // Then — qrAuthenticating fires once on entry, again as the deduplicated
        // single step across scan/exchange (the spec dedupes adjacent same-step
        // calls, which the underlying tracker handles).
        #expect(analytics.steps.contains(.qrAuthenticating))
        #expect(analytics.steps.contains(.qrNumberMatch))
    }

    @Test func error_emits_qrError_step_and_failure_string() async {
        // Given
        let strategy = MockQRLoginStrategy()
        strategy.scanResult = .failure(.init(kind: .network, phase: .scan, primaryAction: .retryFailedPhase))
        let analytics = SpyAnalytics()
        let viewModel = QRLoginViewModel(strategy: strategy, analytics: analytics, pollIntervalSeconds: 0)

        // When
        await viewModel.start()

        // Then
        #expect(analytics.steps.last == .qrError)
        #expect(analytics.failures == ["Network:Scan"])
    }
}

// MARK: - Helpers

@MainActor
private func makeScanResult(realNumber: String = "428") -> QRLoginScanResult {
    QRLoginScanResult(sessionID: "sess",
                      realNumber: realNumber,
                      expiresInSeconds: 90,
                      tokenHash: "hash",
                      subtitle: .host("shop.example"))
}

@MainActor
private func waitForState(_ viewModel: QRLoginViewModel,
                          matching predicate: @escaping @MainActor (QRLoginViewModel.State) -> Bool) async {
    while predicate(viewModel.state) == false {
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
}

// MARK: - Mocks

@MainActor
private final class MockQRLoginStrategy: QRLoginStrategy {
    let protocol_: QRLoginErrorMapper.Protocol_ = .selfHosted

    var scanResult: Result<QRLoginScanResult, QRLoginUserFacingError> = .failure(.init(kind: .unexpected,
                                                                                       phase: .scan,
                                                                                       primaryAction: .retryFailedPhase))
    var pollResults: [Result<QRLoginSessionState, QRLoginNetworkError>] = []
    var exchangeResult: Result<QRLoginExchangeOutcome, QRLoginUserFacingError> =
        .failure(.init(kind: .unexpected, phase: .exchange, primaryAction: .retryFailedPhase))

    private(set) var scanCount = 0
    private(set) var exchangeCalls: [String] = []
    private var pollIndex = 0

    func scan() async -> Result<QRLoginScanResult, QRLoginUserFacingError> {
        scanCount += 1
        return scanResult
    }

    func makePollAttempt() -> QRLoginPollingLoop.PollAttempt {
        return { [self] in
            // The view model's `pollingTask` runs on the cooperative pool; it
            // calls this attempt via the loop. The actor isolation isn't
            // perfect from the static analyser's POV, but `@unchecked Sendable`
            // would only paper over it — instead we keep mutation safe by
            // running tests entirely on @MainActor with no concurrent calls.
            await MainActor.run { [self] in }
            let index = await MainActor.run { [self] in
                let i = pollIndex
                pollIndex += 1
                return i
            }
            let result = await MainActor.run { [self] in
                pollResults.indices.contains(index) ? pollResults[index] : pollResults.last ?? .failure(.malformed)
            }
            switch result {
            case .success(let status):
                return status
            case .failure(let error):
                throw error
            }
        }
    }

    func exchange(grant: String) async -> Result<QRLoginExchangeOutcome, QRLoginUserFacingError> {
        exchangeCalls.append(grant)
        return exchangeResult
    }
}

@MainActor
private final class SpyAnalytics: QRLoginAnalyticsTracking {
    private(set) var steps: [AuthenticatorAnalyticsTracker.Step] = []
    private(set) var clicks: [AuthenticatorAnalyticsTracker.ClickTarget] = []
    private(set) var failures: [String] = []

    func setFlow(_ flow: AuthenticatorAnalyticsTracker.Flow) {}
    func trackStep(_ step: AuthenticatorAnalyticsTracker.Step) { steps.append(step) }
    func trackClick(_ click: AuthenticatorAnalyticsTracker.ClickTarget) { clicks.append(click) }
    func trackFailure(_ failure: String) { failures.append(failure) }
}
