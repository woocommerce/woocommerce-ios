import Combine
import Foundation

/// Read-only access to the store currently affected by a connection error.
///
public protocol StoreConnectionErrorMonitoring {
    /// Identifier of the store currently affected, or `nil` when no store is affected.
    ///
    var affectedSiteID: Int64? { get }

    /// Emits the affected store identifier on every change, starting with the current value.
    ///
    var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> { get }
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
/// itself as soon as a request to that store succeeds again — no manual reset once the merchant fixes
/// their site. Not persisted: a relaunch starts clean and re-detects if the store is still unreachable.
///
public final class StoreConnectionErrorMonitor: StoreConnectionErrorMonitoring, StoreConnectionErrorRecording {
    public static let shared = StoreConnectionErrorMonitor()

    private let subject = CurrentValueSubject<Int64?, Never>(nil)
    private let queue = DispatchQueue(label: "StoreConnectionErrorMonitor", attributes: .concurrent)

    init() {}

    public var affectedSiteID: Int64? {
        queue.sync { subject.value }
    }

    public var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> {
        subject.eraseToAnyPublisher()
    }

    func recordInvalidSignature(siteID: Int64) {
        queue.async(flags: .barrier) { [subject] in
            guard subject.value != siteID else {
                return
            }
            subject.send(siteID)
        }
    }

    func recordSuccessfulConnection(siteID: Int64) {
        queue.async(flags: .barrier) { [subject] in
            guard subject.value == siteID else {
                return
            }
            subject.send(nil)
        }
    }
}
