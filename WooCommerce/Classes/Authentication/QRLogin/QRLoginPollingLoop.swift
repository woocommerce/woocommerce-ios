import Foundation
import Yosemite

/// Drives the `GET /qr-login-session-status` poll until a terminal outcome is
/// reached.
///
/// Behaviour from spec §5.3 / §6.1:
///   - Cadence: 2 seconds between attempts. The first tick is *immediate* —
///     no leading delay.
///   - Transient-error budget: up to 3 consecutive transient errors are
///     tolerated; the 4th consecutive failure surfaces. Any non-error
///     response resets the counter.
///   - "Fail closed" on `approved` with a missing / blank `exchange_grant` —
///     treated as `expired` so the UI shows a terminal screen instead of
///     spinning forever.
///   - Unknown state values are routed through the terminal-state mapper,
///     which translates them defensively to `signInTimedOut`.
///   - Cancellation: cooperative — observes `Task.checkCancellation()` before
///     every poll and sleep.
final class QRLoginPollingLoop {

    enum Outcome: Equatable {
        case approved(exchangeGrant: String)
        case error(QRLoginUserFacingError)
        case cancelled
    }

    /// A single poll attempt. Implementations call the appropriate Remote and
    /// map its endpoint-specific session status into the shared `QRLoginSessionState`.
    typealias PollAttempt = () async throws -> QRLoginSessionState

    /// Async sleep — injectable so tests can run the loop instantly.
    typealias Sleeper = (TimeInterval) async throws -> Void

    private let attempt: PollAttempt
    private let sleeper: Sleeper
    private let protocol_: QRLoginErrorMapper.Protocol_
    private let pollInterval: TimeInterval
    private let transientErrorBudget: Int

    init(protocol_: QRLoginErrorMapper.Protocol_,
                pollInterval: TimeInterval = 2.0,
                transientErrorBudget: Int = 3,
                sleeper: @escaping Sleeper = QRLoginPollingLoop.defaultSleeper,
                attempt: @escaping PollAttempt) {
        self.protocol_ = protocol_
        self.pollInterval = pollInterval
        self.transientErrorBudget = transientErrorBudget
        self.sleeper = sleeper
        self.attempt = attempt
    }

    func run() async -> Outcome {
        var transientFailures = 0

        while true {
            if Task.isCancelled { return .cancelled }

            do {
                let state = try await attempt()
                transientFailures = 0 // any non-error response resets the budget

                switch state {
                case .approved(let grant):
                    if let grant, grant.isEmpty == false {
                        return .approved(exchangeGrant: grant)
                    }
                    // Fail closed (spec §5.1.2 / §5.2.2).
                    return .error(.init(kind: .signInTimedOut, phase: .poll, primaryAction: .scanAgain))

                case .scanned:
                    break // keep polling

                case .rejected, .expired, .consumed, .unknown:
                    if let mapped = QRLoginErrorMapper.userFacingError(forTerminalState: state,
                                                                       protocol_: protocol_) {
                        return .error(mapped)
                    }
                    // Defensive: should be unreachable, but if the mapper says
                    // "not terminal" we treat as expired.
                    return .error(.init(kind: .signInTimedOut, phase: .poll, primaryAction: .scanAgain))
                }
            } catch let networkError as QRLoginNetworkError {
                if let mapped = QRLoginErrorMapper.userFacingError(forPoll: networkError, protocol_: protocol_) {
                    return .error(mapped) // terminal HTTP error
                }
                transientFailures += 1
                if transientFailures > transientErrorBudget {
                    return .error(QRLoginErrorMapper.userFacingError(forPollAfterThreshold: networkError))
                }
            } catch is CancellationError {
                return .cancelled
            } catch {
                // Any non-QRLoginNetworkError throws are unexpected — count
                // them toward the transient budget so we don't spin forever.
                transientFailures += 1
                if transientFailures > transientErrorBudget {
                    return .error(.init(kind: .unexpected, phase: .poll, primaryAction: .retryFailedPhase))
                }
            }

            do {
                try await sleeper(pollInterval)
            } catch {
                return .cancelled
            }
        }
    }

    static let defaultSleeper: Sleeper = { interval in
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
}
