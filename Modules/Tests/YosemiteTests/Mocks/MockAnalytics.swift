import Foundation
import WooFoundation
import os

/// Simple mock for Analytics protocol used in Yosemite tests
final class MockAnalytics: Analytics {
    struct TrackedEvent {
        let eventName: String
        let properties: [AnyHashable: Any]?
        let error: Error?
    }

    private struct State {
        var trackedEvents: [TrackedEvent] = []
        var userHasOptedIn = true
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    var trackedEvents: [TrackedEvent] {
        state.withLockUnchecked { $0.trackedEvents }
    }

    var userHasOptedIn: Bool {
        get { state.withLockUnchecked { $0.userHasOptedIn } }
        set { state.withLockUnchecked { $0.userHasOptedIn = newValue } }
    }
    let analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()

    func initialize() {}

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        state.withLockUnchecked {
            $0.trackedEvents.append(TrackedEvent(eventName: eventName, properties: properties, error: error))
        }
    }

    func refreshUserData() {}

    func setUserHasOptedOut(_ optedOut: Bool) {
        userHasOptedIn = !optedOut
    }
}

/// Minimal mock for AnalyticsProvider
final class MockAnalyticsProvider: AnalyticsProvider {
    func refreshUserData(completion: @escaping @Sendable () -> Void) { completion() }
    func track(_ eventName: String) {}
    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {}
    func clearEvents() {}
    func clearUsers() {}
}
