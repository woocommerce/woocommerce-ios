import Foundation
import Testing
import Networking
@testable import WooCommerce

@Suite(.timeLimit(.minutes(1)))
struct QRLoginPollingLoopTests {

    // MARK: - Terminal success outcomes

    @Test func run_when_approved_with_grant_then_returns_approved() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .approved, exchangeGrant: "grant-abc"))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        #expect(outcome == .approved(exchangeGrant: "grant-abc"))
        await #expect(queue.callCount == 1)
        await #expect(queue.sleepCalls == 0) // terminal first attempt — no sleep
    }

    @Test func run_when_approved_with_blank_grant_then_fails_closed_as_signInTimedOut() async {
        // Given — spec §5.1.2 / §5.2.2 fail-closed rule.
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .approved, exchangeGrant: nil))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .signInTimedOut)
    }

    @Test func run_keeps_polling_on_scanned_then_returns_on_terminal_state() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .scanned, exchangeGrant: nil)),
            .success(QRLoginSessionStatus(state: .scanned, exchangeGrant: nil)),
            .success(QRLoginSessionStatus(state: .approved, exchangeGrant: "g"))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        #expect(outcome == .approved(exchangeGrant: "g"))
        await #expect(queue.callCount == 3)
        await #expect(queue.sleepCalls == 2) // one sleep between each pair of attempts
    }

    @Test func run_when_terminal_rejected_then_returns_signInDenied() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .rejected, exchangeGrant: nil))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .signInDenied)
    }

    @Test func run_when_terminal_expired_then_returns_signInTimedOut() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .expired, exchangeGrant: nil))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .signInTimedOut)
    }

    @Test func run_when_terminal_consumed_on_wpCom_then_returns_alreadySignedInElsewhere() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .consumed, exchangeGrant: nil))
        ])
        let loop = makeLoop(queue: queue, protocol_: .wpCom)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .alreadySignedInElsewhere)
    }

    @Test func run_when_unknown_state_then_returns_signInTimedOut_defensively() async {
        // Given
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .unknown, exchangeGrant: nil))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .signInTimedOut)
    }

    // MARK: - Transient-error budget (spec §5.1.2)

    @Test func run_when_three_transient_errors_followed_by_success_then_budget_resets() async {
        // Given — three transient errors are absorbed, the 4th would surface.
        let queue = ResponseQueue(responses: [
            .failure(.network),
            .failure(.network),
            .failure(.network),
            .success(QRLoginSessionStatus(state: .approved, exchangeGrant: "g"))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        #expect(outcome == .approved(exchangeGrant: "g"))
        await #expect(queue.callCount == 4)
    }

    @Test func run_when_four_consecutive_transient_errors_then_surfaces_user_facing_error() async {
        // Given
        let queue = ResponseQueue(responses: Array(repeating: .failure(.network), count: 4))
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .network)
        #expect(error.primaryAction == .retryFailedPhase)
        await #expect(queue.callCount == 4)
    }

    @Test func run_when_three_transients_then_scanned_then_three_more_transients_then_keeps_polling() async {
        // Given — the spec is explicit: "any non-error poll response
        // (`scanned`) resets the counter to zero". So we should be able to
        // sustain repeated transient-failure runs as long as a `scanned`
        // arrives within 3.
        let queue = ResponseQueue(responses: [
            .failure(.network), .failure(.network), .failure(.network),
            .success(QRLoginSessionStatus(state: .scanned, exchangeGrant: nil)),
            .failure(.network), .failure(.network), .failure(.network),
            .success(QRLoginSessionStatus(state: .approved, exchangeGrant: "g"))
        ])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        #expect(outcome == .approved(exchangeGrant: "g"))
    }

    // MARK: - Terminal HTTP errors

    @Test func run_when_terminal_http_error_then_surfaces_immediately() async {
        // Given — 404 on self-hosted poll is terminal (the merchant's plugin
        // does not expose the endpoint).
        let queue = ResponseQueue(responses: [.failure(.notFound)])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .storeUnsupported)
        await #expect(queue.callCount == 1)
    }

    @Test func run_when_rate_limited_then_terminal_rateLimited() async {
        // Given
        let queue = ResponseQueue(responses: [.failure(.rateLimited)])
        let loop = makeLoop(queue: queue)

        // When
        let outcome = await loop.run()

        // Then
        guard case let .error(error) = outcome else {
            Issue.record("Expected .error, got \(outcome)")
            return
        }
        #expect(error.kind == .rateLimited)
    }

    // MARK: - Cancellation

    @Test func run_when_task_cancelled_then_returns_cancelled() async {
        // Given — block forever so we can cancel the parent task.
        let queue = ResponseQueue(responses: [
            .success(QRLoginSessionStatus(state: .scanned, exchangeGrant: nil))
        ], hangAfterRunningOut: true)
        let loop = makeLoop(queue: queue)

        let task = Task { await loop.run() }

        // When — cancel after the first attempt.
        try? await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()

        // Then
        let outcome = await task.value
        #expect(outcome == .cancelled)
    }
}

// MARK: - Test doubles

private extension QRLoginPollingLoopTests {

    func makeLoop(queue: ResponseQueue,
                  protocol_: QRLoginErrorMapper.Protocol_ = .selfHosted) -> QRLoginPollingLoop {
        QRLoginPollingLoop(
            protocol_: protocol_,
            pollInterval: 0, // skip waiting in tests
            sleeper: { _ in try await queue.recordSleep() },
            attempt: { try await queue.next() }
        )
    }
}

/// Plays back a scripted sequence of poll responses, captures call/sleep
/// counts, and (optionally) hangs once the script runs out so cancellation
/// tests have something to interrupt.
private final actor ResponseQueue {
    enum Response {
        case success(QRLoginSessionStatus)
        case failure(QRLoginNetworkError)
    }

    private var responses: [Response]
    private var index = 0
    private(set) var callCount = 0
    private(set) var sleepCalls = 0
    private let hangAfterRunningOut: Bool

    init(responses: [Response], hangAfterRunningOut: Bool = false) {
        self.responses = responses
        self.hangAfterRunningOut = hangAfterRunningOut
    }

    func next() async throws -> QRLoginSessionStatus {
        callCount += 1
        if index < responses.count {
            let response = responses[index]
            index += 1
            switch response {
            case .success(let status):
                return status
            case .failure(let error):
                throw error
            }
        }
        guard hangAfterRunningOut else {
            // Default: keep producing the last response so we don't infinite-loop.
            return QRLoginSessionStatus(state: .scanned, exchangeGrant: nil)
        }
        // Suspend forever — cancellation tests rely on this.
        try await Task.sleep(nanoseconds: UInt64.max)
        return QRLoginSessionStatus(state: .scanned, exchangeGrant: nil)
    }

    func recordSleep() async throws {
        sleepCalls += 1
        try Task.checkCancellation()
    }
}
