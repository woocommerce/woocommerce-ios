import Combine
import Foundation
import os

/// Read-only access to the store currently affected by a connection error.
///
public protocol StoreConnectionErrorMonitoring {
    /// Identifier of the store currently affected, or `nil` when no store is affected.
    ///
    var affectedSiteID: Int64? { get }

    /// Emits the affected store identifier on the main queue on every change, starting with the
    /// current value.
    ///
    @MainActor var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> { get }
}

/// Write-only counterpart used by the networking layer to report the outcome of a request.
///
protocol StoreConnectionErrorRecording {
    /// Records that a request for the given store was rejected with `rest_invalid_signature`.
    ///
    func recordInvalidSignature(siteID: Int64)

    /// Records that a request for the given store succeeded, clearing any error recorded for it.
    ///
    func recordSuccessfulConnection(siteID: Int64)
}

/// App-wide holder for stores that reject our requests with Jetpack's `rest_invalid_signature` error.
///
/// The error means signature verification failed on the merchant's own WordPress site, which the app
/// cannot fix and cannot retry its way out of. It is recorded here so the app can stop syncing in the
/// background and tell the merchant what is going on instead of failing silently.
///
/// The state is keyed by site so it only affects the store that is actually unreachable, and it clears
/// itself as soon as a request to that store through the Jetpack tunnel succeeds again — no manual reset
/// once the merchant fixes their site. Not persisted: a relaunch starts clean and re-detects if the store
/// is still unreachable.
///
public final class StoreConnectionErrorMonitor: StoreConnectionErrorMonitoring, StoreConnectionErrorRecording, Sendable {
    public static let shared = StoreConnectionErrorMonitor()

    /// The value itself, guarded by a lock because the networking layer writes it from whatever queue a
    /// response arrives on while the app reads it from the main thread.
    ///
    private let storedSiteID = OSAllocatedUnfairLock<Int64?>(initialState: nil)

    /// The notification channel. It belongs to the main actor because a Combine subject is not
    /// `Sendable`; every announcement is queued from inside the lock, so the main queue receives the
    /// changes in the order they were applied and what it last announces always matches `affectedSiteID`.
    ///
    @MainActor private let subject = CurrentValueSubject<Int64?, Never>(nil)

    init() {}

    public var affectedSiteID: Int64? {
        storedSiteID.withLock { $0 }
    }

    @MainActor
    public var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> {
        subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func recordInvalidSignature(siteID: Int64) {
        updateAffectedSiteID(to: siteID) { $0 != siteID }
    }

    func recordSuccessfulConnection(siteID: Int64) {
        updateAffectedSiteID(to: nil) { $0 == siteID }
    }
}

private extension StoreConnectionErrorMonitor {
    /// Applies a change only when `shouldUpdate` accepts the current value, and queues its announcement in
    /// the same breath.
    ///
    /// The announcement is queued inside the critical section on purpose. Two requests to the same store
    /// can finish at once, and queueing after unlocking lets their sends overtake each other, leaving the
    /// publisher's last value disagreeing with `affectedSiteID`. Subscribers never run here: the send runs
    /// later on the main queue, so holding the lock cannot reach anyone else's code.
    ///
    func updateAffectedSiteID(to newValue: Int64?, if shouldUpdate: @Sendable (Int64?) -> Bool) {
        storedSiteID.withLock { storedSiteID in
            guard shouldUpdate(storedSiteID) else {
                return
            }
            storedSiteID = newValue
            DispatchQueue.main.async {
                self.subject.send(newValue)
            }
        }
    }
}
