import Foundation
import Synchronization
import Testing
import WooFoundation

/// Catalog events carry string properties. Snapshot them before crossing back to the test.
final class MockPOSCatalogAnalytics: Analytics, Sendable {
    struct TrackedEvent: Sendable {
        let eventName: String
        let properties: [String: String]?
        let error: Error?
    }

    private struct State {
        var trackedEvents: [TrackedEvent] = []
        var userHasOptedIn = true
    }

    private let state = Mutex(State())

    var trackedEvents: [TrackedEvent] {
        state.withLock { $0.trackedEvents }
    }

    var userHasOptedIn: Bool {
        get { state.withLock { $0.userHasOptedIn } }
        set { state.withLock { $0.userHasOptedIn = newValue } }
    }

    var analyticsProvider: AnalyticsProvider { MockAnalyticsProvider() }

    func initialize() {}
    func refreshUserData() {}

    func setUserHasOptedOut(_ optedOut: Bool) {
        userHasOptedIn = !optedOut
    }

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        let snapshot = properties as? [String: String]
        guard properties == nil || snapshot != nil else {
            Issue.record("Catalog analytics mock requires string keys and values")
            return
        }
        let event = TrackedEvent(eventName: eventName, properties: snapshot, error: error)
        state.withLock { $0.trackedEvents.append(event) }
    }
}
